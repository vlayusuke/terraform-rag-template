# ================================================================================
# Local Values in production
# ================================================================================

# ================================================================================
# Environment
# ================================================================================
locals {
  env             = "prd"
  repository_name = "vlayusuke"
}


# ================================================================================
# Network
# ================================================================================
locals {
  vpc_cidr_block       = "10.20.0.0/16"
  default_gateway_cidr = "0.0.0.0/0"
}


# ================================================================================
# Amazon S3
# ================================================================================
locals {
  transition_days = 365
  expire_days     = 1827
}


# ================================================================================
# Amazon Aurora Serverless v2
# ================================================================================
locals {
  rds_cluster_instance_count = 1

  # Postgres Role Name
  rds_postgres_role_name = "bedrock_role"

  # Titan Text Embeddings v2
  vector_dimention = 1024

  schema_name = "bedrock_integration"
  table_name  = "bedrock_kb"
  index_name  = "bedrock_kb_embedding_idx"
}


# ================================================================================
# Amazon CloudWatch
# ================================================================================
locals {
  retention_in_days = 180

  lambda_functions = toset([
    aws_lambda_function.poke_api.function_name,
    aws_lambda_function.response_api.function_name,
    aws_lambda_function.lambda_log_error_alert.function_name,
    aws_lambda_function.lambda_metric_alarm.function_name,
  ])

  enabled_cloudwatch_logs_exports_for_aurora = toset([
    "instance",
    "postgresql",
    "iam-db-auth-error",
  ])

  aurora_log_types = aws_kinesis_firehose_delivery_stream.aurora_logs_postgresql.arn

  enabled_cloudwatch_logs_exports_for_bedrock = toset([
    "knowledge-bases",
  ])

  bedrock_log_types = aws_kinesis_firehose_delivery_stream.bedrock_logs_knowledge_bases.arn
}


# ================================================================================
# Amazon Bedrock Models
# ================================================================================
locals {
  bedrock_foundation_model     = "anthropic.claude-sonnet-4-5-20250929-v1:0"
  bedrock_knowledge_base_model = "amazon.titan-embed-text-v2:0"
}


# ================================================================================
# AWS WAFv2 Rule Notification ARN
# ================================================================================
locals {
  wafv2_rule_notification_arn = "arn:aws:sns:us-east-1:248400274283:aws-managed-waf-rule-notifications"
}
