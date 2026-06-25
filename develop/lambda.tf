# ================================================================================
# AWS Lambda Functions for Request API
# ================================================================================
resource "aws_lambda_function" "request_api" {
  function_name    = "lmd-apigw-request-api"
  role             = aws_iam_role.lambda_request_api.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.request_api.output_path
  source_code_hash = data.archive_file.request_api.output_base64sha256
  runtime          = "python3.14"
  timeout          = 30
  memory_size      = 128

  tags = {
    Name = "${local.project}-${local.env}-lmd-apigw-request-api"
  }
}

data "archive_file" "request_api" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/request-api"
  output_path = "${path.module}/artifacts/request-api.zip"
}

resource "aws_lambda_permission" "request_api" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.request_api.function_name
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
}


# ================================================================================
# AWS Lambda Functions for Response API
# ================================================================================
resource "aws_lambda_function" "response_api" {
  function_name    = "lmd-apigw-response-api"
  role             = aws_iam_role.lambda_response_api.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.response_api.output_path
  source_code_hash = data.archive_file.response_api.output_base64sha256
  runtime          = "python3.14"
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      AGENT_ID       = aws_bedrockagent_agent.bedrock_agent.id
      AGENT_ALIAS_ID = aws_bedrockagent_agent_alias.bedrock_agent.agent_alias_id
    }
  }

  tags = {
    Name = "${local.project}-${local.env}-lmd-apigw-response-api"
  }
}

data "archive_file" "response_api" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/response-api"
  output_path = "${path.module}/artifacts/response-api.zip"
}

resource "aws_lambda_permission" "response_api" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.response_api.function_name
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
}


# ===============================================================================
# AWS Lambda Function for Amazon CloudWatch Logs error alert
# ===============================================================================
resource "aws_lambda_function" "lambda_log_error_alert" {
  function_name    = "lmd-cwt-log-error-alert"
  role             = aws_iam_role.lambda_cloudwatch.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_log_error_alert.output_path
  source_code_hash = data.archive_file.lambda_log_error_alert.output_base64sha256
  runtime          = "python3.14"
  timeout          = 10
  memory_size      = 128

  architectures = [
    "arm64",
  ]

  environment {
    variables = {
      hook_url = var.hook_url_app
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-lmd-cwt-log-error-alert"
  }
}

data "archive_file" "lambda_log_error_alert" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/log-error-alert"
  output_path = "${path.module}/artifacts/lmd-cwt-log-error-alert.zip"
}

resource "aws_lambda_permission" "lambda_cloudwatch_app" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_log_error_alert.function_name
  principal     = "logs.${local.region}.amazonaws.com"
  source_arn    = "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
}


# ===============================================================================
# AWS Lambda Function for Amazon CloudWatch Metric Alarm
# ===============================================================================
resource "aws_lambda_function" "lambda_metric_alarm" {
  function_name    = "lmd-cwt-metric-alarm"
  role             = aws_iam_role.lambda_cloudwatch.arn
  handler          = "lambda_function.lambda_handler"
  filename         = data.archive_file.lambda_metric_alarm.output_path
  source_code_hash = data.archive_file.lambda_metric_alarm.output_base64sha256
  runtime          = "python3.14"
  timeout          = 10
  memory_size      = 128

  architectures = [
    "arm64",
  ]

  environment {
    variables = {
      hook_url = var.hook_url_app
      region   = local.region
    }
  }

  lifecycle {
    ignore_changes = [
      source_code_hash,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-lmd-cwt-metric-alarm"
  }
}

data "archive_file" "lambda_metric_alarm" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/lambda/metric-alarm"
  output_path = "${path.module}/artifacts/lmd-cwt-metric-alarm.zip"
}

resource "aws_lambda_permission" "lambda_metric_alarm" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_metric_alarm.function_name
  principal     = "cloudwatch.amazonaws.com"
  source_arn    = "arn:aws:cloudwatch:${local.region}:${data.aws_caller_identity.current.account_id}:alarm:*"
}
