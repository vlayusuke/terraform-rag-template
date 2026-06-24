# ===============================================================================
# Amazon Data Firehose Stream (Amazon Aurora logs)
# ===============================================================================
resource "aws_kinesis_firehose_delivery_stream" "aurora_postgresql_logs" {
  name        = "${local.project}-${local.env}-adf-aur-postgresql-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.aurora_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/postgresql/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-aur-postgresql-logs-to-s3"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "aurora_instance_logs" {
  name        = "${local.project}-${local.env}-adf-aur-instance-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.aurora_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/instance/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-aur-instance-logs-to-s3"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "aurora_iam_db_auth_error_logs" {
  name        = "${local.project}-${local.env}-adf-aur-iam-db-auth-error-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.aurora_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/auth-error/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-aur-iam-db-auth-error-logs-to-s3"
  }
}


# ===============================================================================
# Amazon Data Firehose Stream (AWS Lambda logs)
# ===============================================================================
resource "aws_kinesis_firehose_delivery_stream" "lambda_logs" {
  for_each    = local.lambda_functions
  name        = "${local.project}-${local.env}-adf-lmd-${each.key}-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.lambda_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/${each.key}/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-lmd-${each.key}-logs-to-s3"
  }
}


# ===============================================================================
# Amazon Data Firehose Stream (Amazon Bedrock logs)
# ===============================================================================
resource "aws_kinesis_firehose_delivery_stream" "bedrock_logs" {
  for_each    = local.bedrock_cloudwatch_log_group
  name        = "${local.project}-${local.env}-adf-brk-${each.key}-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.bedrock_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/${each.key}/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-brk-${each.key}-logs-to-s3"
  }
}


# ===============================================================================
# Amazon Data Firehose Stream (Amazon SNS logs)
# ===============================================================================
resource "aws_kinesis_firehose_delivery_stream" "sns_logs" {
  name        = "${local.project}-${local.env}-adf-sns-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.sns_logs.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-sns-logs-to-s3"
  }
}


# ===============================================================================
# Amazon Data Firehose Stream (Amazon EC2 Bastion logs)
# ===============================================================================
resource "aws_kinesis_firehose_delivery_stream" "ec2_bastion_logs" {
  name        = "${local.project}-${local.env}-adf-ec2-bastion-logs-to-s3"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn           = aws_iam_role.amazon_data_firehose.arn
    bucket_arn         = aws_s3_bucket.bastion.arn
    buffering_size     = 64
    buffering_interval = 300
    prefix             = "${local.env}/ec2-bastion-logs/"
    compression_format = "GZIP"
  }

  server_side_encryption {
    enabled  = true
    key_type = "AWS_OWNED_CMK"
  }

  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-adf-ec2-bastion-logs-to-s3"
  }
}
