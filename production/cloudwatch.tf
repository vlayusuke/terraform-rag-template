# ===============================================================================
# Amazon CloudWatch Log group for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_cloudwatch_log_group" "aurora_postgres" {
  for_each          = local.aurora_cloudwatch_log_group
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}-cwtlog"
  retention_in_days = local.retention_in_days
  log_group_class   = "STANDARD"

  tags = {
    Name = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}-cwtlog"
  }
}

resource "aws_cloudwatch_log_stream" "aurora_postgres" {
  for_each       = local.aurora_cloudwatch_log_group
  name           = "${local.project}-${local.env}-cw-rds-${each.key}-cwtstream"
  log_group_name = aws_cloudwatch_log_group.aurora_postgres[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "aurora_postgres_to_firehose" {
  for_each        = local.aurora_adf_stream_arns
  name            = "${local.project}-${local.env}-cwt-rds-${each.key}-to-adf"
  log_group_name  = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}-to-adf"
  filter_pattern  = "?Warning ?Error"
  destination_arn = each.value
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_to_amazon_data_firehose,
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "aurora_postgres_to_lambda" {
  for_each        = local.aurora_cloudwatch_log_group
  name            = "${local.project}-${local.env}-cwt-rds-${each.key}-to-lmd"
  log_group_name  = "/aws/rds/cluster/${aws_rds_cluster.aurora_postgres.cluster_identifier}/${each.key}-to-lmd"
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon Bedrock
# ===============================================================================
resource "aws_cloudwatch_log_group" "bedrock" {
  for_each          = local.bedrock_cloudwatch_log_group
  name              = "/aws/bedrock/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}-cwlog"
  retention_in_days = local.retention_in_days
  log_group_class   = "STANDARD"

  tags = {
    Name = "/aws/bedrock/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "bedrock" {
  for_each       = local.bedrock_cloudwatch_log_group
  name           = "${local.project}-${local.env}-cwt-${each.key}-cwtstream"
  log_group_name = aws_cloudwatch_log_group.bedrock[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "bedrock_to_firehose" {
  for_each        = local.bedrock_cloudwatch_log_group
  name            = "${local.project}-${local.env}-cwt-${each.key}-to-adf"
  log_group_name  = "/aws/bedrock/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}-to-adf"
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.bedrock_logs[each.key].arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_to_amazon_data_firehose,
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "bedrock_to_lambda" {
  for_each        = local.bedrock_cloudwatch_log_group
  name            = "${local.project}-${local.env}-cwt-${each.key}-to-lmd"
  log_group_name  = "/aws/bedrock/${aws_bedrockagent_knowledge_base.knowledge_base.name}/${each.key}-to-lmd"
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon EC2 Bastion
# ===============================================================================
resource "aws_cloudwatch_log_group" "ec2_bastion" {
  name              = "${local.project}-${local.env}-cwt-ec2-bastion-cwlog"
  retention_in_days = local.retention_in_days
  log_group_class   = "STANDARD"

  tags = {
    Name = "${local.project}-${local.env}-cwt-ec2-bastion-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "ec2_bastion" {
  name           = "${local.project}-${local.env}-cwt-ec2-bastion-cwstream"
  log_group_name = aws_cloudwatch_log_group.ec2_bastion.name
}

resource "aws_cloudwatch_log_subscription_filter" "ec2_bastion_to_firehose" {
  name            = "${local.project}-${local.env}-cwt-ec2-bastion-to-adf"
  log_group_name  = aws_cloudwatch_log_group.ec2_bastion.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.ec2_bastion_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_to_amazon_data_firehose,
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "ec2_bastion_to_lambda" {
  name            = "${local.project}-${local.env}-cwt-ec2-bastion-to-lmd"
  log_group_name  = aws_cloudwatch_log_group.ec2_bastion.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon SNS
# ===============================================================================
resource "aws_cloudwatch_log_group" "sns" {
  name              = "${local.project}-${local.env}-cwt-sns-cwlog"
  retention_in_days = local.retention_in_days
  log_group_class   = "STANDARD"

  tags = {
    Name = "${local.project}-${local.env}-cwt-sns-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "sns" {
  name           = "${local.project}-${local.env}-cwt-sns-cwstream"
  log_group_name = aws_cloudwatch_log_group.sns.name
}

resource "aws_cloudwatch_log_subscription_filter" "sns_to_firehose" {
  name            = "${local.project}-${local.env}-cwt-sns-to-adf"
  log_group_name  = aws_cloudwatch_log_group.sns.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.sns_logs.arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_to_amazon_data_firehose,
  ]
}

resource "aws_cloudwatch_log_subscription_filter" "sns_to_lambda" {
  name            = "${local.project}-${local.env}-cwt-sns-to-lmd"
  log_group_name  = aws_cloudwatch_log_group.sns.name
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}


# ===============================================================================
# Amazon CloudWatch Log group for AWS Lambda Function
# ===============================================================================
resource "aws_cloudwatch_log_group" "lambda_function" {
  for_each          = local.lambda_functions
  name              = "/aws/lambda/${each.key}-cwtlog"
  retention_in_days = local.retention_in_days
  log_group_class   = "STANDARD"

  tags = {
    Name = "/aws/lambda/${each.key}-cwtlog"
  }
}

resource "aws_cloudwatch_log_stream" "lambda_function" {
  for_each       = local.lambda_functions
  name           = "${local.project}-${local.env}-cwt-lmd-${each.key}-cwstream"
  log_group_name = aws_cloudwatch_log_group.lambda_function[each.key].name
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_function_to_lambda" {
  for_each        = local.lambda_functions
  name            = "${local.project}-${local.env}-cwt-lmd-${each.key}-to-lmd"
  log_group_name  = aws_cloudwatch_log_group.lambda_function[each.key].name
  filter_pattern  = "?ERROR"
  destination_arn = aws_lambda_function.lambda_log_error_alert.arn
}

resource "aws_cloudwatch_log_subscription_filter" "lambda_function_to_firehose" {
  for_each        = local.lambda_functions
  name            = "${local.project}-${local.env}-cwt-lmd-${each.key}-to-adf"
  log_group_name  = aws_cloudwatch_log_group.lambda_function[each.key].name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.lambda_logs[each.key].arn
  role_arn        = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.arn
  distribution    = "ByLogStream"

  depends_on = [
    aws_iam_role_policy_attachment.cloudwatch_logs_to_amazon_data_firehose,
  ]
}


# ===============================================================================
# Amazon CloudWatch Log group for Amazon Data Firehose
# ===============================================================================
resource "aws_cloudwatch_log_group" "adf" {
  name              = "/aws/kinesisfirehose/${local.project}-${local.env}-cwt-adf-cwlog"
  retention_in_days = local.retention_in_days

  tags = {
    Name = "/aws/kinesisfirehose/${local.project}-${local.env}-cwt-adf-cwlog"
  }
}

resource "aws_cloudwatch_log_stream" "adf" {
  name           = "${local.project}-${local.env}-cwt-adf-cwstream"
  log_group_name = aws_cloudwatch_log_group.adf.name
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "aurora_postgres_acuutilization_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-aur-serverless-acuutilization-high-alarm"
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
    Name = "${local.project}-${local.env}-cwt-aur-serverless-acuutilization-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "aurora_postgres_database_capacity" {
  alarm_name          = "${local.project}-${local.env}-cwt-aur-serverless-database-capacity-alarm"
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
    Name = "${local.project}-${local.env}-cwt-aur-serverless-database-capacity-alarm"
  }
}


# ===============================================================================
# Amazon CloudWatch Metrics for AWS Lambda
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.project}-${local.env}-cwt-lmd-errors-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-lmd-errors-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_throttles" {
  alarm_name          = "${local.project}-${local.env}-cwt-lmd-throttles-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-lmd-throttles-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "lambda_concurrent_executions" {
  alarm_name          = "${local.project}-${local.env}-cwt-lmd-concurrent-executions-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ConcurrentExecutions"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Maximum"
  threshold           = data.aws_servicequotas_service_quota.lambda_concurrent_executions.value * 0.8
  treat_missing_data  = "notBreaching"

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-lmd-concurrent-executions-alarm"
  }
}

data "aws_servicequotas_service_quota" "lambda_concurrent_executions" {
  quota_name   = "Concurrent executions"
  service_code = "lambda"
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon EC2 Bastion
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "ec2_bastion_cpu_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-ec2-bastion-cpu-high-alarm"
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
    Name = "${local.project}-${local.env}-cwt-ec2-bastion-cpu-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_bastion_memory_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-ec2-bastion-memory-high-alarm"
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
    Name = "${local.project}-${local.env}-cwt-ec2-bastion-memory-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_bastion_disk_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-ec2-bastion-disk-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "DiskUtilization"
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
    Name = "${local.project}-${local.env}-cwt-ec2-bastion-disk-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "ec2_bastion_status_check_failed" {
  alarm_name          = "${local.project}-${local.env}-cwt-ec2-bastion-status-check-failed-alarm"
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
    Name = "${local.project}-${local.env}-cwt-ec2-bastion-status-check-failed-alarm"
  }
}


# ===============================================================================
# Amazon CloudWatch Metrics for Amazon Bedrock
# ===============================================================================
resource "aws_cloudwatch_metric_alarm" "bedrock_latency_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-brk-latency-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "Latency"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 6000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = local.bedrock_knowledge_base_model
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-brk-latency-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_invocation_count_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-brk-invocation-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "InvocationCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 36000000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = local.bedrock_knowledge_base_model
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-brk-invocation-count-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_error_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-brk-error-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "Error"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = local.bedrock_knowledge_base_model
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-brk-error-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_input_token_count_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-brk-input-token-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "InputTokenCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 100000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = local.bedrock_knowledge_base_model
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-brk-input-token-count-high-alarm"
  }
}

resource "aws_cloudwatch_metric_alarm" "bedrock_output_token_count_high" {
  alarm_name          = "${local.project}-${local.env}-cwt-brk-output-token-count-high-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "OutputTokenCount"
  namespace           = "AWS/Bedrock"
  period              = 60
  statistic           = "Minimum"
  threshold           = 100000
  treat_missing_data  = "notBreaching"

  dimensions = {
    ModelId = local.bedrock_knowledge_base_model
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-brk-output-token-count-high-alarm"
  }
}


# ================================================================================
# Amazon CloudWatch Metrics for Amazon CloudWatch Synthetics Canary Check Request API
# ================================================================================
resource "aws_cloudwatch_metric_alarm" "synthetics_canary_check_request_api_failed" {
  alarm_name          = "${local.project}-${local.env}-cwt-syn-canary-check-request-api-failed-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "SuccessPercent"
  namespace           = "CloudWatchSynthetics"
  period              = 300
  statistic           = "Average"
  threshold           = 90
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm when the Synthetics Canary check request API success percent is less than 90%"

  dimensions = {
    CanaryName = aws_synthetics_canary.check_request_api.name
  }

  alarm_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  ok_actions = [
    aws_sns_topic.metric_alarm.arn,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cwt-syn-canary-check-request-api-failed-alarm"
  }
}


# ================================================================================
# Amazon CloudFront Access Logs V2 to S3 via Amazon CloudWatch Log Delivery
# ================================================================================
resource "aws_cloudwatch_log_delivery_source" "cloudfront_access_logs" {
  provider     = aws.virginia
  name         = "${local.project}-${local.env}-cwt-cft-access-logs-v2-source"
  log_type     = "ACCESS_LOGS"
  resource_arn = aws_cloudfront_distribution.main.arn

  tags = {
    Name = "${local.project}-${local.env}-cwt-cft-access-logs-v2-source"
  }
}

resource "aws_cloudwatch_log_delivery_destination" "cloudfront_access_logs" {
  provider                  = aws.virginia
  name                      = "${local.project}-${local.env}-cwt-cft-access-logs-v2-destination"
  delivery_destination_type = "S3"
  output_format             = "parquet"

  delivery_destination_configuration {
    destination_resource_arn = "${aws_s3_bucket.cloudfront_logs.arn}/v2/"
  }

  tags = {
    Name = "${local.project}-${local.env}-cwt-cft-access-logs-v2-destination"
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
    Name = "${local.project}-${local.env}-cwt-cft-access-logs-v2-delivery"
  }
}
