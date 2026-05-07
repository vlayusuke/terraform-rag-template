# ================================================================================
# Amazon Aurora Serverless v2 Cluster
# ================================================================================

# ================================================================================
# Amazon Aurora Serverless v2
# Data APIをONにしてHTTPエンドポイント経由でDBの変更、操作をできるようにしている
# Data APIは決められたengine, engine_version, engine_modeでないと使えないので注意
# インスタンスのクラスをServerless v2にするか、provisionedではr系のインスタンスが必要になる
# https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/data-api.html
# ================================================================================
resource "aws_rds_cluster" "aurora_postgres" {
  cluster_identifier = "${local.project}-${local.env}-aurora-serverless-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.10"
  engine_mode        = "provisioned"
  availability_zones = local.availability_zones
  database_name      = split("-", local.project)[0]
  port               = 5432
  master_username    = local.rds_postgres_role_name
  kms_key_id         = aws_kms_key.aurora.arn
  apply_immediately  = true

  manage_master_user_password  = true
  deletion_protection          = false
  storage_encrypted            = true
  enable_http_endpoint         = true
  backup_retention_period      = 7
  preferred_backup_window      = "07:00-09:00"
  preferred_maintenance_window = "sun:09:00-sun:13:00"

  vpc_security_group_ids = [
    aws_security_group.rds.id,
  ]

  db_subnet_group_name = aws_db_subnet_group.aurora_postgres.name

  enabled_cloudwatch_logs_exports       = local.enabled_cloudwatch_logs_exports_for_aurora
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  performance_insights_kms_key_id       = aws_kms_key.aurora.arn

  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      master_password,
      engine_version,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-aurora-serverless-cluster"
  }
}

resource "aws_db_subnet_group" "aurora_postgres" {
  name = "${local.project}-${local.env}-aurora-serverless-subg"
  subnet_ids = [
    for subnet in aws_subnet.production_private :
    subnet.id
  ]

  tags = {
    Name = "${local.project}-${local.env}-aurora-serverless-subg"
  }
}


# ================================================================================
# Amazon Aurora Serverless v2 Instance
# ================================================================================
resource "aws_rds_cluster_instance" "aurora_postgres_instance" {
  count                                 = local.rds_cluster_instance_count
  identifier                            = "${local.project}-${local.env}-aurora-serverless-instance-${count.index + 1}"
  cluster_identifier                    = aws_rds_cluster.aurora_postgres.id
  instance_class                        = "db.serverless"
  engine                                = "aurora-postgresql"
  engine_version                        = aws_rds_cluster.aurora_postgres.engine_version
  db_subnet_group_name                  = aws_db_subnet_group.aurora_postgres.name
  db_parameter_group_name               = aws_db_parameter_group.aurora_postgres.name
  publicly_accessible                   = false
  auto_minor_version_upgrade            = true
  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.aurora.arn
  performance_insights_retention_period = 7
  ca_cert_identifier                    = "rds-ca-rsa2048-g1"
  promotion_tier                        = count.index
  apply_immediately                     = true

  lifecycle {
    ignore_changes = [
      engine_version,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-aurora-serverless-instance-${count.index + 1}"
  }
}


# ===============================================================================
# DB Parameter Group
# ===============================================================================
resource "aws_db_parameter_group" "aurora_postgres" {
  name        = "${local.project}-${local.env}-aurora-serverless-instance-dbpg"
  family      = "aurora-postgresql15"
  description = "Parameter group for Aurora PostgreSQL for ${local.project}"

  tags = {
    Name = "${local.project}-${local.env}-aurora-serverless-instance-dbpg"
  }
}


# ================================================================================
# Setup Vector Database
# Data APIを介してDBの設定を行う
# ================================================================================
resource "terraform_data" "setup_vector_database" {

  triggers_replace = [
    aws_rds_cluster.aurora_postgres.id,
  ]

  # https://docs.aws.amazon.com/AmazonRDS/latest/AuroraUserGuide/AuroraPostgreSQL.VectorDB.html
  # Install pgvector and check the version
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/01_install_pgvector.sh"
    environment = {
      REGION      = local.region
      CLUSTER_ARN = aws_rds_cluster.aurora_postgres.arn

      # Data APIではsecrets managerで認証するため
      SECRET_ARN    = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.aurora_postgres.database_name
    }
  }

  # Create a specific schema that Bedrock can use to query the data
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/02_create_schema.sh"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.aurora_postgres.arn
      SECRET_ARN    = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.aurora_postgres.database_name
      SCHEMA_NAME   = local.schema_name
    }
  }

  # Grant the bedrock_user permission to manage the bedrock_integration schema
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/03_create_role.sh"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.aurora_postgres.arn
      SECRET_ARN    = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.aurora_postgres.database_name
      SCHEMA_NAME   = local.schema_name
      ROLE_NAME     = local.rds_postgres_role_name
      PASSWORD      = "PleaseChangePassword1234"
    }
  }

  # Login as the bedrock_user and create a table in the bedrock_integration schema
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/04_grant_schema.sh"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.aurora_postgres.arn
      SECRET_ARN    = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.aurora_postgres.database_name
      ROLE_NAME     = local.rds_postgres_role_name
      SCHEMA_NAME   = local.schema_name
    }
  }

  # Create an index with the cosine operator which the bedrock can use to query the data.
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/05_create_table.sh"
    environment = {
      REGION              = local.region
      CLUSTER_ARN         = aws_rds_cluster.aurora_postgres.arn
      SECRET_ARN          = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME       = aws_rds_cluster.aurora_postgres.database_name
      EMBEDDING_DIMENSION = local.vector_dimention
      SCHEMA_NAME         = local.schema_name
      TABLE_NAME          = local.table_name
    }
  }

  # Create an index with the cosine operator which the bedrock can use to query the data.
  provisioner "local-exec" {
    command = "bash ./src/rds_setting_scripts/06_create_index.sh"
    environment = {
      REGION        = local.region
      CLUSTER_ARN   = aws_rds_cluster.aurora_postgres.arn
      SECRET_ARN    = aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn
      DATABASE_NAME = aws_rds_cluster.aurora_postgres.database_name
      SCHEMA_NAME   = local.schema_name
      TABLE_NAME    = local.table_name
      INDEX_NAME    = local.index_name
    }
  }

  # Writer instance will start and execute the SQL statement
  depends_on = [
    aws_rds_cluster_instance.aurora_postgres_instance,
  ]
}
