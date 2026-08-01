# ===============================================================================
# Amazon EventBridge (Check Config)
# ===============================================================================
resource "aws_cloudwatch_event_rule" "check_config" {
  name           = "${local.project}-${local.env}-ebd-check-config"
  description    = "Check Config Notification"
  event_bus_name = "default"
  state          = "ENABLED"
  force_destroy  = true

  event_pattern = jsonencode({
    "source" : [
      "aws.config"
    ],
    "detail-type" : [
      "Config Rules Complete Change"
    ],
    "detail" : {
      "messageType" : [
        "ComplianceChangeNotification"
      ]
    }
  })

  tags = {
    Name = "${local.project}-${local.env}-ebd-check-config"
  }
}

resource "aws_cloudwatch_event_target" "check_config" {
  rule      = aws_cloudwatch_event_rule.check_config.name
  target_id = aws_sns_topic.event_notifications_audit.name
  arn       = aws_sns_topic.event_notifications_audit.arn
}


# ===============================================================================
# Amazon EventBridge (Check Non Compliance)
# ===============================================================================
resource "aws_cloudwatch_event_rule" "config_non_compliance" {
  name           = "${local.project}-${local.env}-ebd-config-non-compliance"
  description    = "EventBridge rule to capture AWS Config non-compliance events"
  event_bus_name = "default"
  state          = "ENABLED"
  force_destroy  = true

  event_pattern = jsonencode({
    "source" : [
      "aws.config"
    ],
    "detail-type" : [
      "Config Rules Compliance Change"
    ],
    "detail" : {
      "complianceType" : [
        "NON_COMPLIANT"
      ]
    }
  })

  tags = {
    Name = "${local.project}-${local.env}-ebd-config-non-compliance"
  }
}

resource "aws_cloudwatch_event_target" "config_non_compliance" {
  rule      = aws_cloudwatch_event_rule.config_non_compliance.name
  target_id = aws_sns_topic.config_notifications.name
  arn       = aws_sns_topic.config_notifications.arn
}


# ==============================================================================
# Amazon EventBridge (AWS Config Configuration Item Changes)
# ==============================================================================
resource "aws_cloudwatch_event_rule" "config_item_change" {
  name           = "${local.project}-${local.env}-ebd-config-item-change"
  description    = "EventBridge rule to capture AWS Config configuration item changes"
  event_bus_name = "default"
  state          = "ENABLED"
  force_destroy  = true

  event_pattern = jsonencode({
    "source" : [
      "aws.config"
    ],
    "detail-type" : [
      "ConfigurationItemChangeNotification",
      "OversizedConfigurationItemChangeNotification"
    ]
  })

  tags = {
    Name = "${local.project}-${local.env}-ebd-config-item-change"
  }
}

resource "aws_cloudwatch_event_target" "config_item_change" {
  rule      = aws_cloudwatch_event_rule.config_item_change.name
  target_id = aws_sns_topic.config_notifications.name
  arn       = aws_sns_topic.config_notifications.arn
}


# ===============================================================================
# Amazon EventBridge (AWS CloudTrail)
# ===============================================================================
resource "aws_cloudwatch_event_rule" "cloudtrail" {
  name           = "${local.project}-${local.env}-ebd-ctl"
  description    = "AWS CloudTrail Notification"
  event_bus_name = "default"
  state          = "ENABLED"
  force_destroy  = true

  event_pattern = jsonencode({
    "source" : [
      "aws.cloudtrail"
    ],
    "detail-type" : [
      "AWS API Call via CloudTrail"
    ],
    "detail" : {
      "eventSource" : [
        "signin.amazonaws.com",
        "monitoring.amazonaws.com",
        "cloudfront.amazonaws.com",
        "iam.amazonaws.com",
        "ec2.amazonaws.com",
        "bedrock.amazonaws.com",
        "rds.amazonaws.com",
        "apigateway.amazonaws.com",
        "lambda.amazonaws.com",
        "kms.amazonaws.com",
        "s3.amazonaws.com",
        "sns.amazonaws.com",
        "ssm.amazonaws.com",
        "secretsmanager.amazonaws.com",
        "logs.amazonaws.com",
        "wafv2.amazonaws.com",
      ]
    }
  })

  tags = {
    Name = "${local.project}-${local.env}-ebd-ctl"
  }
}

resource "aws_cloudwatch_event_target" "cloudtrail" {
  rule      = aws_cloudwatch_event_rule.cloudtrail.name
  target_id = aws_sns_topic.event_notifications_audit.name
  arn       = aws_sns_topic.event_notifications_audit.arn
}
