# ===============================================================================
# Amazon CloudWatch Log group for Aurora Serverless v2
# ===============================================================================
resource "aws_cloudwatch_log_group" "aurora_postgres" {
  for_each          = local.enabled_cloudwatch_logs_exports_for_aurora
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "aurora_postgres" {
  for_each       = local.enabled_cloudwatch_logs_exports_for_aurora
  name           = "${local.project}-${local.env}-cw-rds-${each.key}-cwstream"
  log_group_name = aws_cloudwatch_log_group.aurora_postgres[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "aurora_postgres_to_firehose" {
  for_each        = local.enabled_cloudwatch_logs_exports_for_aurora
  name            = "${local.project}-${local.env}-cw-rds-${each.key}-to-firehose"
  log_group_name  = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.aurora_postgres_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "aurora_postgres_to_lambda" {
  for_each        = local.enabled_cloudwatch_logs_exports_for_aurora
  name            = aws_lambda_function.lambda_log_error_alert.function_name
  log_group_name  = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}"
  filter_pattern  = "?Warning ?Error"
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Bedrock Knowledge base
# ===============================================================================
resource "aws_cloudwatch_log_group" "bedrock_knowledge_base" {
  for_each          = local.enabled_cloudwatch_logs_exports_for_bedrock
  name              = "/aws/bedrock/knowledge-bases/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "/aws/bedrock/knowledge-bases/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "bedrock_knowledge_base" {
  for_each       = local.enabled_cloudwatch_logs_exports_for_bedrock
  name           = "${local.project}-${local.env}-cw-brk-knowledge-base-${each.key}-cwstream"
  log_group_name = aws_cloudwatch_log_group.bedrock_knowledge_base[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "bedrock_knowledge_base_to_firehose" {
  name            = "${local.project}-${local.env}-cw-brk-knowledge-base-to-firehose"
  log_group_name  = "/aws/bedrock/knowledge-bases/${aws_bedrockagent_knowledge_base.knowledge_base.name}/knowledge-base"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.bedrock_knowledge_base_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "bedrock_knowledge_base_to_lambda" {
  name            = aws_lambda_function.lambda_log_error_alert.function_name
  log_group_name  = "/aws/bedrock/knowledge-bases/${aws_bedrockagent_knowledge_base.knowledge_base.name}/knowledge-base"
  filter_pattern  = "?Warning ?Error"
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon EC2 Bastion
# ===============================================================================
resource "aws_cloudwatch_log_group" "bastion" {
  name              = "${local.project}-${local.env}-bastion"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "${local.project}-${local.env}-cw-bastion-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "bastion" {
  name           = "${local.project}-${local.env}-cw-bastion-cwstream"
  log_group_name = aws_cloudwatch_log_group.bastion.name
}

resource "aws_cloudwatch_log_subscription_filter" "bastion_to_firehose" {
  name            = "${local.project}-${local.env}-cw-bastion-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.bastion.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.bastion_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "bastion_to_lambda" {
  name            = aws_lambda_function.lambda_log_error_alert.function_name
  log_group_name  = aws_cloudwatch_log_group.bastion.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon SNS
# ===============================================================================
resource "aws_cloudwatch_log_group" "sns" {
  name              = "${local.project}-${local.env}-sns"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "${local.project}-${local.env}-cw-sns-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "sns" {
  name           = "${local.project}-${local.env}-cw-sns-cwstream"
  log_group_name = aws_cloudwatch_log_group.sns.name
}

resource "aws_cloudwatch_log_subscription_filter" "sns_to_firehose" {
  name            = "${local.project}-${local.env}-cw-sns-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.sns.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.sns_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
}

resource "aws_cloudwatch_log_subscription_filter" "sns_to_lambda" {
  name            = aws_lambda_function.lambda_log_error_alert.function_name
  log_group_name  = aws_cloudwatch_log_group.sns.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for AWS Lambda Functions
# ===============================================================================
resource "aws_cloudwatch_log_group" "lambda_functions" {
  for_each          = local.lambda_functions
  name              = "/aws/lambda/${each.key}-cwlog"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "/aws/lambda/${each.key}-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "lambda_functions" {
  for_each       = local.lambda_functions
  name           = "${local.project}-${local.env}-cw-lambda-${each.key}-cwstream"
  log_group_name = aws_cloudwatch_log_group.lambda_functions[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_functions_to_lambda" {
  for_each        = local.lambda_functions
  name            = aws_lambda_function.lambda_log_error_alert.function_name
  log_group_name  = aws_cloudwatch_log_group.lambda_functions[each.key].name
  filter_pattern  = "ERROR"
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_functions_to_firehose" {
  for_each        = local.lambda_functions
  name            = "${local.project}-${local.env}-cw-lambda-${each.key}-to-firehose"
  log_group_name  = aws_cloudwatch_log_group.lambda_functions[each.key].name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.lambda_logs[each.key].arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon Data Firehose
# ===============================================================================
resource "aws_cloudwatch_log_group" "adf" {
  name              = "/aws/kinesisfirehose/${local.project}-${local.env}-cw-adf-cwlog"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "/aws/kinesisfirehose/${local.project}-${local.env}-cw-adf-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "adf" {
  name           = "${local.project}-${local.env}-cw-adf-cwstream"
  log_group_name = aws_cloudwatch_log_group.adf.name
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "aurora_postgres_acuutilization_high" {
  alarm_name          = "${local.project}-${local.env}-cw-aurora-postgres-acuutilization-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ACUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_postgres.cluster_identifier
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-aurora-postgres-acuutilization-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_postgres_database_capacity" {
  alarm_name          = "${local.project}-${local.env}-cw-aurora-postgres-database-capacity-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "ServerlessDatabaseCapacity"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.aurora_postgres.cluster_identifier
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-aurora-postgres-database-capacity-alarm"
  }
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon EC2 Bastion
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "bastion_cpu_high" {
  alarm_name          = "${local.project}-${local.env}-cw-bastion-cpu-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2_bastion.id
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-bastion-cpu-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bastion_memory_high" {
  alarm_name          = "${local.project}-${local.env}-cw-bastion-memory-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Maximum"
  threshold           = 80
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2_bastion.id
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-bastion-memory-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bastion_status_check_failed" {
  alarm_name          = "${local.project}-${local.env}-cw-bastion-status-check-failed-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    InstanceId = aws_instance.ec2_bastion.id
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-bastion-status-check-failed-alarm"
  }
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon Bedrock
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "bedrock_latency_high" {
  alarm_name          = "${local.project}-${local.env}-cw-brk-latency-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 6000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = "amazon.titan-embed-text-v2:0"
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-brk-latency-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_invocation_count_high" {
  alarm_name          = "${local.project}-${local.env}-cw-brk-invocation-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "InvocationCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 36000000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = "amazon.titan-embed-text-v2:0"
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-brk-invocation-count-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_error_high" {
  alarm_name          = "${local.project}-${local.env}-cw-brk-error-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "Error"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = "amazon.titan-embed-text-v2:0"
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-brk-error-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_input_token_count_high" {
  alarm_name          = "${local.project}-${local.env}-cw-brk-input-token-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "InputTokenCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 100000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = "amazon.titan-embed-text-v2:0"
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-brk-input-token-count-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_output_token_count_high" {
  alarm_name          = "${local.project}-${local.env}-cw-brk-output-token-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "OutputTokenCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 100000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = "amazon.titan-embed-text-v2:0"
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cw-brk-output-token-count-high-alarm"
  }
}


# ================================================================================
# Amazon CloudFront Access Logs V2 to S3 via Amazon CloudWatch Log Delivery
# ================================================================================
resource "aws_cloudwatch_log_delivery_source" "cloudfront_access_logs" {
  provider     = aws.virginia
  name         = "${local.project}-${local.env}-cw-cloudfront-access-logs-source"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.production.arn

  tags = {
    Name = "${local.project}-${local.env}-cw-cloudfront-access-logs-source"
  }
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront_access_logs" {
  provider                  = aws.virginia
  name                      = "${local.project}-${local.env}-cw-cloudfront-access-logs-destination"
  delivery_destination_type = "S3"
  output_format             = "parquet"

  delivery_destination_configuration {
    destination_resource_arn = "${aws_s3_bucket.cloudfront_logs.arn}/v2/"
  }

  tags = {
    Name = "${local.project}-${local.env}-cw-cloudfront-access-logs-destination"
  }
}

resource "aws_cloudwatch_log_delivery" "cloudfront_access_logs" {
  provider                 = aws.virginia
  delivery_source_name     = aws_cloudwatch_log_delivery_source.cloudfront_access_logs.name
  delivery_destination_arn = aws_cloudwatch_log_delivery_destination.cloudfront_access_logs.arn

  s3_delivery_configuration {
    suffix_path = "/${data.aws_caller_identity.current.account_id}/{DistributionId}/{yyyy}/{MM}/{dd}/{HH}/"
  }

  tags = {
    Name = "${local.project}-${local.env}-cw-cloudfront-access-logs-delivery"
  }
}
