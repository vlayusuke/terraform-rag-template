# ===============================================================================
# AWS IAM OIDC Provider for GitHub
# ===============================================================================
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  thumbprint_list = [
    data.tls_certificate.github.certificates[0].sha1_fingerprint,
  ]

  client_id_list = [
    "sts.amazonaws.com",
  ]

  tags = {
    Name = "${local.project}-${local.env}-iam-oidc-provider-idp"
  }
}

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}


# ===============================================================================
# AWS IAM for GitHub Actions Deploy
# ===============================================================================
resource "aws_iam_role" "github_actions_deploy" {
  name               = "${local.project}-${local.env}-iam-github-actions-deploy-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_deploy_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-deploy-role"
  }
}

data "aws_iam_policy_document" "github_actions_deploy_assume" {
  statement {
    sid    = "OIDCFederate"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}/*",
      ]
    }
  }

  statement {
    sid    = "OIDCFederateRef"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}:ref:refs/heads/main",
        "repo:${local.repository_name}:ref:refs/heads/*",
      ]
    }
  }
}


# ===============================================================================
# AWS IAM for Source Code Backup
# ===============================================================================
resource "aws_iam_role" "github_actions_backup" {
  name               = "${local.project}-${local.env}-iam-github-actions-backup-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.github_actions_backup_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-backup-role"
  }
}

data "aws_iam_policy_document" "github_actions_backup_assume" {
  statement {
    sid    = "OIDCFederate"
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
    ]
    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com",
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${local.repository_name}/*",
      ]
    }
  }
}

resource "aws_iam_policy" "github_actions_backup" {
  name   = "${local.project}-${local.env}-iam-github-actions-backup-policy"
  policy = data.aws_iam_policy_document.github_actions_backup.json

  tags = {
    Name = "${local.project}-${local.env}-iam-github-actions-backup-policy"
  }
}

data "aws_iam_policy_document" "github_actions_backup" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${local.project}-*-*",
      "arn:aws:s3:::${local.project}-*-*/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_backup" {
  role       = aws_iam_role.github_actions_backup.name
  policy_arn = aws_iam_policy.github_actions_backup.arn
}


# ===============================================================================
# AWS IAM for AWS Lambda to Request API
# ===============================================================================
resource "aws_iam_role" "lambda_request_api" {
  name               = "${local.project}-${local.env}-iam-lmd-request-api-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_request_api_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-request-api-role"
  }
}

data "aws_iam_policy_document" "lambda_request_api_assume" {
  statement {
    sid    = "LambdaAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "lambda_request_api" {
  name   = "${local.project}-${local.env}-iam-lmd-request-api-policy"
  policy = data.aws_iam_policy_document.lambda_request_api.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-request-api-policy"
  }
}

data "aws_iam_policy_document" "lambda_request_api" {
  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_request_api" {
  role       = aws_iam_role.lambda_request_api.name
  policy_arn = aws_iam_policy.lambda_request_api.arn
}


# ===============================================================================
# AWS IAM for AWS Lambda to Response API
# ===============================================================================
resource "aws_iam_role" "lambda_response_api" {
  name               = "${local.project}-${local.env}-iam-lmd-response-api-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_response_api_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-response-api-role"
  }
}

data "aws_iam_policy_document" "lambda_response_api_assume" {
  statement {
    sid    = "LambdaAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "lambda_response_api" {
  name   = "${local.project}-${local.env}-iam-lmd-response-api-policy"
  policy = data.aws_iam_policy_document.lambda_response_api.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-response-api-policy"
  }
}

data "aws_iam_policy_document" "lambda_response_api" {
  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }

  statement {
    sid    = "BedrockAgentAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeAgent",
      "bedrock:ListAgents",
      "bedrock:GetAgent",
      "bedrock:InvokeAgent",
      "bedrock:InvokeAgentAlias",
    ]
    resources = [
      "arn:aws:bedrock:${local.region}:${data.aws_caller_identity.current.account_id}:agent-alias/${aws_bedrockagent_agent.bedrock_agent.agent_id}/${aws_bedrockagent_agent_alias.bedrock_agent.agent_alias_id}",
      "arn:aws:bedrock:${local.region}:${data.aws_caller_identity.current.account_id}:agent-alias/${aws_bedrockagent_agent.bedrock_agent.agent_id}/${aws_bedrockagent_agent_alias.bedrock_agent.agent_alias_id}/*",
      aws_bedrockagent_agent.bedrock_agent.agent_arn,
    ]
  }

  statement {
    sid    = "BedrockModelAccess"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:ListFoundationModels",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_response_api" {
  role       = aws_iam_role.lambda_response_api.name
  policy_arn = aws_iam_policy.lambda_response_api.arn
}


# ===============================================================================
# AWS IAM for AWS Lambda (CloudWatch Error Alert)
# ===============================================================================
resource "aws_iam_role" "lambda_cloudwatch" {
  name               = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_cloudwatch_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-role"
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch_assume" {
  statement {
    sid    = "LambdaAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "lambda_cloudwatch" {
  name   = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-policy"
  policy = data.aws_iam_policy_document.lambda_cloudwatch.json

  tags = {
    Name = "${local.project}-${local.env}-iam-lmd-cwt-logs-error-alert-policy"
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch" {
  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${local.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.project}-${local.env}-*:*",
    ]
  }

  statement {
    sid    = "SNSPublish"
    effect = "Allow"
    actions = [
      "sns:Publish",
    ]
    resources = [
      aws_sns_topic.event_alarm.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda_cloudwatch.name
  policy_arn = aws_iam_policy.lambda_cloudwatch.arn
}


# ===============================================================================
# AWS IAM for Amazon Data Firehose
# ===============================================================================
resource "aws_iam_role" "amazon_data_firehose" {
  name               = "${local.project}-${local.env}-iam-adf-role"
  assume_role_policy = data.aws_iam_policy_document.amazon_data_firehose_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-adf-role"
  }
}

data "aws_iam_policy_document" "amazon_data_firehose_assume" {
  statement {
    sid    = "ADFAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "amazon_data_firehose" {
  name   = "${local.project}-${local.env}-iam-adf-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.amazon_data_firehose.json

  tags = {
    Name = "${local.project}-${local.env}-iam-adf-policy"
  }
}

data "aws_iam_policy_document" "amazon_data_firehose" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.aurora_logs.arn,
      "${aws_s3_bucket.aurora_logs.arn}/*",
      aws_s3_bucket.bedrock_logs.arn,
      "${aws_s3_bucket.bedrock_logs.arn}/*",
      aws_s3_bucket.lambda_logs.arn,
      "${aws_s3_bucket.lambda_logs.arn}/*",
      aws_s3_bucket.sns_logs.arn,
      "${aws_s3_bucket.sns_logs.arn}/*",
      aws_s3_bucket.bastion_logs.arn,
      "${aws_s3_bucket.bastion_logs.arn}/*",
    ]
  }

  statement {
    sid    = "PutLogEvents"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      aws_cloudwatch_log_stream.aurora_postgres["postgresql"].arn,
      "${aws_cloudwatch_log_stream.aurora_postgres["postgresql"].arn}:*",
      aws_cloudwatch_log_stream.aurora_postgres["instance"].arn,
      "${aws_cloudwatch_log_stream.aurora_postgres["instance"].arn}:*",
      aws_cloudwatch_log_stream.aurora_postgres["iam-db-auth-error"].arn,
      "${aws_cloudwatch_log_stream.aurora_postgres["iam-db-auth-error"].arn}:*",
      aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.lambda_log_error_alert.function_name].arn,
      "${aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.lambda_log_error_alert.function_name].arn}:*",
      aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.lambda_metric_alarm.function_name].arn,
      "${aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.lambda_metric_alarm.function_name].arn}:*",
      aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.request_api.function_name].arn,
      "${aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.request_api.function_name].arn}:*",
      aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.response_api.function_name].arn,
      "${aws_cloudwatch_log_stream.lambda_function[aws_lambda_function.response_api.function_name].arn}:*",
      aws_cloudwatch_log_stream.bedrock["knowledge-base"].arn,
      "${aws_cloudwatch_log_stream.bedrock["knowledge-base"].arn}:*",
      aws_cloudwatch_log_stream.sns.arn,
      "${aws_cloudwatch_log_stream.sns.arn}:*",
      aws_cloudwatch_log_stream.adf.arn,
      "${aws_cloudwatch_log_stream.adf.arn}:*",
      aws_cloudwatch_log_stream.ec2_bastion.arn,
      "${aws_cloudwatch_log_stream.ec2_bastion.arn}:*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "amazon_data_firehose" {
  role       = aws_iam_role.amazon_data_firehose.name
  policy_arn = aws_iam_policy.amazon_data_firehose.arn
}


# ===============================================================================
# AWS IAM for Amazon Bedrock Agent
# ===============================================================================
resource "aws_iam_role" "bedrock_agent" {
  name               = "${local.project}-${local.env}-iam-brk-agent-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.bedrock_agent_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-brk-agent-role"
  }
}

data "aws_iam_policy_document" "bedrock_agent_assume" {
  statement {
    sid    = "BedrockAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "bedrock.amazonaws.com",
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        "arn:aws:bedrock:${local.region}:${data.aws_caller_identity.current.account_id}:agent/*"
      ]
    }
  }
}

resource "aws_iam_policy" "bedrock_agent" {
  name   = "${local.project}-${local.env}-iam-brk-agent-policy"
  policy = data.aws_iam_policy_document.bedrock_agent.json

  tags = {
    Name = "${local.project}-${local.env}-iam-brk-agent-policy"
  }
}

data "aws_iam_policy_document" "bedrock_agent" {
  statement {
    sid    = "BedrockInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
    ]
    resources = [
      data.aws_bedrock_foundation_model.bedrock_agent_model.model_arn,
    ]
  }

  statement {
    sid    = "BedrockRetrieve"
    effect = "Allow"
    actions = [
      "bedrock:Retrieve",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:GetObject",
    ]
    resources = [
      "arn:aws:s3:::${local.project}-${local.env}-bedrock-documents/*",
      "arn:aws:s3:::${local.project}-${local.env}-bedrock-documents",
      "arn:aws:s3:::${local.project}-${local.env}-api-schema/*",
      "arn:aws:s3:::${local.project}-${local.env}-api-schema",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "bedrock_agent" {
  role       = aws_iam_role.bedrock_agent.name
  policy_arn = aws_iam_policy.bedrock_agent.arn
}


# ===============================================================================
# AWS IAM for Amazon Bedrock Knowledge base
# ===============================================================================
resource "aws_iam_role" "bedrock_knowledge_base" {
  name               = "${local.project}-${local.env}-iam-brk-knowledge-base-role"
  assume_role_policy = data.aws_iam_policy_document.bedrock_knowledge_base_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-brk-knowledge-base-role"
  }
}

data "aws_iam_policy_document" "bedrock_knowledge_base_assume" {
  statement {
    sid    = "BedrockAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "bedrock.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "bedrock_knowledge_base" {
  name   = "${local.project}-${local.env}-iam-brk-knowledge-base-policy"
  policy = data.aws_iam_policy_document.bedrock_knowledge_base.json

  tags = {
    Name = "${local.project}-${local.env}-iam-brk-knowledge-base-policy"
  }
}

data "aws_iam_policy_document" "bedrock_knowledge_base" {
  statement {
    sid    = "FoundationModelAccess"
    effect = "Allow"
    actions = [
      "bedrock:ListFoundationModels",
      "bedrock:ListCustomModels",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "BedrockInvoke"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
    ]
    resources = [
      data.aws_bedrock_foundation_model.bedrock_knowledge_base_model.model_arn,
    ]
  }

  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
    ]
    resources = [
      aws_s3_bucket.rag_document.arn,
      "${aws_s3_bucket.rag_document.arn}/*",
    ]
  }

  statement {
    sid    = "RDSAccess"
    effect = "Allow"
    actions = [
      "rds:DescribeDBClusters",
      "rds:DescribeDBInstances",
      "rds-db:connect",
      "rds-data:BatchExecuteStatement",
      "rds-data:ExecuteStatement",
    ]
    resources = [
      aws_rds_cluster.aurora_postgres.arn,
      aws_rds_cluster_instance.aurora_postgres_instance[0].arn,
      aws_rds_cluster_instance.aurora_postgres_instance[1].arn,
    ]
  }

  statement {
    sid    = "SecretsManagerAccess"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      aws_secretsmanager_secret.postgresql_app_password.arn,
      aws_rds_cluster.aurora_postgres.master_user_secret[0].secret_arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "bedrock_knowledge_base" {
  role       = aws_iam_role.bedrock_knowledge_base.name
  policy_arn = aws_iam_policy.bedrock_knowledge_base.arn
}


# ================================================================================
# AWS IAM for Amazon Aurora Serverless v2
# ================================================================================
resource "aws_iam_role" "rds_iam_auth" {
  name               = "${local.project}-${local.env}-iam-rds-iam-auth-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rds_iam_auth_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-rds-iam-auth-role"
  }
}

data "aws_iam_policy_document" "rds_iam_auth_assume" {
  statement {
    sid    = "RDSAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "rds_iam_auth" {
  name   = "${local.project}-${local.env}-iam-rds-iam-auth-policy"
  policy = data.aws_iam_policy_document.rds_iam_auth.json

  tags = {
    Name = "${local.project}-${local.env}-iam-rds-iam-auth-policy"
  }
}

data "aws_iam_policy_document" "rds_iam_auth" {
  statement {
    sid    = "GetDataases"
    effect = "Allow"
    actions = [
      "rds-db:connect",
    ]
    resources = [
      "arn:aws:rds-db:${local.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_rds_cluster.aurora_postgres.cluster_identifier}/${local.rds_postgres_role_name}",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "rds_iam_auth" {
  role       = aws_iam_role.rds_iam_auth.name
  policy_arn = aws_iam_policy.rds_iam_auth.arn
}


# ================================================================================
# AWS IAM for Amazon Aurora Serverless v2 Performance Insights
# ================================================================================
resource "aws_iam_role" "rds_performance_insights" {
  name               = "${local.project}-${local.env}-iam-rds-performance-insights-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.rds_performance_insights_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-rds-performance-insights-role"
  }
}

data "aws_iam_policy_document" "rds_performance_insights_assume" {
  statement {
    sid    = "RDSPInsightsAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "rds_performance_insights" {
  name   = "${local.project}-${local.env}-iam-rds-performance-insights-policy"
  policy = data.aws_iam_policy_document.rds_performance_insights.json

  tags = {
    Name = "${local.project}-${local.env}-iam-rds-performance-insights-policy"
  }
}

data "aws_iam_policy_document" "rds_performance_insights" {
  statement {
    sid    = "GetPerformanceInsightsData"
    effect = "Allow"
    actions = [
      "rds:DescribeDBInstances",
      "rds:DescribeDBClusters",
    ]
    resources = [
      "arn:aws:rds:${local.region}:${data.aws_caller_identity.current.account_id}:db:*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "rds_performance_insights" {
  role       = aws_iam_role.rds_performance_insights.name
  policy_arn = aws_iam_policy.rds_performance_insights.arn
}


# ================================================================================
# Amazon EC2 Instance Profile for Bastion
# ================================================================================
resource "aws_iam_instance_profile" "bastion" {
  name = "${local.project}-iam-ec2-bastion-profile"
  role = aws_iam_role.bastion.name

  tags = {
    Name = "${local.project}-${local.env}-iam-ec2-bastion-profile"
  }
}

resource "aws_iam_role" "bastion" {
  name               = "${local.project}-iam-ec2-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-ec2-bastion-role"
  }
}

data "aws_iam_policy_document" "bastion_assume" {
  statement {
    sid    = "EC2Assume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "bastion" {
  name   = "${local.project}-iam-ec2-bastion-policy"
  policy = data.aws_iam_policy_document.bastion.json

  tags = {
    Name = "${local.project}-${local.env}-iam-ec2-bastion-policy"
  }
}

data "aws_iam_policy_document" "bastion" {
  statement {
    sid    = "S3Access"
    effect = "Allow"
    actions = [
      "s3:Get*",
    ]
    resources = [
      "${aws_s3_bucket.bastion.arn}/*",
      aws_s3_bucket.bastion.arn,
    ]
  }

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      aws_cloudwatch_log_group.ec2_bastion.arn,
      "${aws_cloudwatch_log_group.ec2_bastion.arn}:log-stream:*",
    ]
  }

  statement {
    sid    = "CloudWatchMetricsAccess"
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "bastion" {
  role       = aws_iam_role.bastion.name
  policy_arn = aws_iam_policy.bastion.arn
}

resource "aws_iam_role_policy_attachment" "bastion_to_ssm" {
  role       = aws_iam_role.bastion.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# ===============================================================================
# AWS IAM for Amazon CloudWatch Logs to Amazon Data Firehose
# ===============================================================================
resource "aws_iam_role" "cloudwatch_logs_to_amazon_data_firehose" {
  name               = "${local.project}-${local.env}-iam-cw-logs-to-adf-role"
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_logs_to_amazon_data_firehose_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-cw-logs-to-adf-role"
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_to_amazon_data_firehose_assume" {
  statement {
    sid    = "CloudWatchLogsAndADFAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com",
        "logs.${local.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "cloudwatch_logs_to_amazon_data_firehose" {
  name   = "${local.project}-${local.env}-iam-iam-cw-logs-to-adf-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.cloudwatch_logs_to_amazon_data_firehose.json

  tags = {
    Name = "${local.project}-${local.env}-iam-iam-cw-logs-to-adf-policy"
  }
}

data "aws_iam_policy_document" "cloudwatch_logs_to_amazon_data_firehose" {
  statement {
    sid    = "AmazonDataFirehoseAccess"
    effect = "Allow"
    actions = [
      "firehose:PutRecord",
      "firehose:PutRecordBatch",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "CloudWatchLogsAccess"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
    ]
    resources = [
      aws_cloudwatch_log_group.aurora_postgres["postgresql"].arn,
      aws_cloudwatch_log_group.aurora_postgres["instance"].arn,
      aws_cloudwatch_log_group.aurora_postgres["iam-db-auth-error"].arn,
      aws_cloudwatch_log_group.lambda_function[aws_lambda_function.request_api.function_name].arn,
      aws_cloudwatch_log_group.lambda_function[aws_lambda_function.response_api.function_name].arn,
      aws_cloudwatch_log_group.lambda_function[aws_lambda_function.lambda_log_error_alert.function_name].arn,
      aws_cloudwatch_log_group.lambda_function[aws_lambda_function.lambda_metric_alarm.function_name].arn,
      aws_cloudwatch_log_group.bedrock["knowledge-base"].arn,
      aws_cloudwatch_log_group.sns.arn,
      aws_cloudwatch_log_group.ec2_bastion.arn,
      aws_cloudwatch_log_group.adf.arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs_to_amazon_data_firehose" {
  role       = aws_iam_role.cloudwatch_logs_to_amazon_data_firehose.name
  policy_arn = aws_iam_policy.cloudwatch_logs_to_amazon_data_firehose.arn
}


# ===============================================================================
# AWS IAM for Amazon Inspector
# ===============================================================================
resource "aws_iam_role" "inspector" {
  name               = "${local.project}-${local.env}-iam-inspector-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.inspector_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-inspector-role"
  }
}

data "aws_iam_policy_document" "inspector_assume" {
  statement {
    sid    = "InspectorAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "inspector.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "inspector" {
  name   = "${local.project}-${local.env}-iam-inspector-policy"
  policy = data.aws_iam_policy_document.inspector.json

  tags = {
    Name = "${local.project}-${local.env}-iam-inspector-policy"
  }
}

data "aws_iam_policy_document" "inspector" {
  statement {
    sid    = "AmazonInspectorAccess"
    effect = "Allow"
    actions = [
      "inspector:StartAssessmentRun",
    ]
    resources = [
      aws_instance.ec2_bastion.arn,
      aws_lambda_function.request_api.arn,
      aws_lambda_function.response_api.arn,
      aws_lambda_function.lambda_log_error_alert.arn,
      aws_lambda_function.lambda_metric_alarm.arn,
    ]
  }
}


# ===============================================================================
# AWS IAM for AWS Chatbot
# ===============================================================================
resource "aws_iam_role" "chatbot" {
  name               = "${local.project}-${local.env}-iam-chatbot-role"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.chatbot_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-chatbot-role"
  }
}

data "aws_iam_policy_document" "chatbot_assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "chatbot.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "chatbot" {
  name   = "${local.project}-${local.env}-iam-chatbot-policy"
  policy = data.aws_iam_policy_document.chatbot.json

  tags = {
    Name = "${local.project}-${local.env}-iam-chatbot-policy"
  }
}

data "aws_iam_policy_document" "chatbot" {
  statement {
    sid    = "SNSAccess"
    effect = "Allow"
    actions = [
      "sns:GetTopicAttributes",
      "sns:SetTopicAttributes",
      "sns:AddPermission",
      "sns:RemovePermission",
      "sns:DeleteTopic",
      "sns:Subscribe",
      "sns:Unsubscribe",
      "sns:ListTopics",
      "sns:ListSubscriptions",
      "sns:ListSubscriptionsByTopic",
      "sns:Receive",
      "sns:ReceiveMessage",
    ]
    resources = [
      aws_sns_topic.metric_alarm.arn,
      aws_sns_topic.event_alarm.arn,
      aws_sns_topic.event_notification.arn,
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values = [
        data.aws_caller_identity.current.account_id,
      ]
    }
  }

  statement {
    sid    = "SNSPublish"
    effect = "Allow"
    actions = [
      "sns:Publish",
      "sns:Subscribe",
    ]
    resources = [
      aws_sns_topic.metric_alarm.arn,
      aws_sns_topic.event_alarm.arn,
      aws_sns_topic.event_notification.arn,
    ]
  }

  statement {
    sid    = "LogAccess"
    effect = "Allow"
    actions = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:CreateLogGroup",
      "logs:DescribeLogGroups",
    ]
    resources = [
      "arn:aws:logs:*:*:log-group:/aws/chatbot/*",
    ]
  }

  statement {
    sid    = "ChatbotAccess"
    effect = "Allow"
    actions = [
      "chatbot:CreateSlackChannelConfiguration",
      "chatbot:DescribeSlackChannelConfigurations",
      "chatbot:DeleteSlackChannelConfiguration",
      "chatbot:UpdateSlackChannelConfiguration",
      "chatbot:CreateMicrosoftTeamsChannelConfiguration",
      "chatbot:DescribeMicrosoftTeamsChannelConfigurations",
      "chatbot:DeleteMicrosoftTeamsChannelConfiguration",
      "chatbot:UpdateMicrosoftTeamsChannelConfiguration",
    ]
    resources = [
      "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/slack-channel/*",
      "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/teams-channel/*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "chatbot" {
  role       = aws_iam_role.chatbot.name
  policy_arn = aws_iam_policy.chatbot.arn
}

resource "aws_iam_role_policy_attachment" "chatbot_read_only_access" {
  role       = aws_iam_role.chatbot.name
  policy_arn = "arn:aws:iam::aws:policy/AWSResourceExplorerReadOnlyAccess"
}


# ===============================================================================
# AWS IAM for AWS Chatbot Guardrail
# ===============================================================================
resource "aws_iam_policy" "chatbot_guardrail" {
  name   = "${local.project}-${local.env}-iam-chatbot-guardrail-policy"
  policy = data.aws_iam_policy_document.chatbot_guardrail.json

  tags = {
    Name = "${local.project}-${local.env}-iam-chatbot-guardrail-policy"
  }
}

data "aws_iam_policy_document" "chatbot_guardrail" {
  statement {
    sid    = "ChatbotAccess"
    effect = "Allow"
    actions = [
      "chatbot:DescribeSlackChannelConfigurations",
      "chatbot:DescribeMicrosoftTeamsChannelConfigurations",
    ]
    resources = [
      "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/slack-channel/*",
      "arn:aws:chatbot::${data.aws_caller_identity.current.account_id}:chat-configuration/teams-channel/*",
    ]
  }
}


# ===============================================================================
# AWS IAM for AWS Data Lifecycle Manager
# Reference: https://docs.aws.amazon.com/ja_jp/ebs/latest/userguide/dlm-prerequisites.html
# Reference: https://docs.aws.amazon.com/ja_jp/ebs/latest/userguide/managed-policies.html
# ===============================================================================
resource "aws_iam_role" "dlm" {
  name               = "${local.project}-${local.env}-iam-dlm-role"
  assume_role_policy = data.aws_iam_policy_document.dlm_assume.json

  tags = {
    Name = "${local.project}-${local.env}-iam-dlm-role"
  }
}

data "aws_iam_policy_document" "dlm_assume" {
  statement {
    sid    = "DLMAssume"
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type = "Service"
      identifiers = [
        "dlm.amazonaws.com",
      ]
    }
  }
}

resource "aws_iam_policy" "dlm" {
  name   = "${local.project}-${local.env}-iam-dlm-policy"
  path   = "/"
  policy = data.aws_iam_policy_document.dlm.json

  tags = {
    Name = "${local.project}-${local.env}-iam-dlm-policy"
  }
}

data "aws_iam_policy_document" "dlm" {
  statement {
    sid    = "DLMFullAccess"
    effect = "Allow"
    actions = [
      "dlm:*",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "AllowPassRole"
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSDataLifecycleManagerDefaultRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/AWSDataLifecycleManagerDefaultRoleForAMIManagement",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSDataLifecycleManagerDefaultRole",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/service-role/AWSDataLifecycleManagerDefaultRoleForAMIManagement",
    ]
  }

  statement {
    sid    = "AllowListRoles"
    effect = "Allow"
    actions = [
      "iam:ListRoles",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "ControlVolumesAndSnapshots"
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:CreateSnapshots",
      "ec2:DeleteSnapshot",
      "ec2:DescribeInstances",
      "ec2:DescribeVolumes",
      "ec2:DescribeSnapshots",
      "ec2:EnableFastSnapshotRestores",
      "ec2:DescribeFastSnapshotRestores",
      "ec2:DisableFastSnapshotRestores",
      "ec2:CopySnapshot",
      "ec2:ModifySnapshotAttribute",
      "ec2:DescribeSnapshotAttribute",
      "ec2:ModifySnapshotTier",
      "ec2:DescribeSnapshotTierStatus",
      "ec2:DescribeRegions",
      "ec2:DescribeAvailabilityZones",
      "kms:DescribeKey",
      "kms:ListAliases",
    ]
    resources = [
      "*",
    ]
  }

  statement {
    sid    = "CreateTags"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*::snapshot/*",
    ]
  }

  statement {
    sid    = "ControlEventRules"
    effect = "Allow"
    actions = [
      "events:PutRule",
      "events:DeleteRule",
      "events:DescribeRule",
      "events:EnableRule",
      "events:DisableRule",
      "events:ListTargetsByRule",
      "events:PutTargets",
      "events:RemoveTargets",
    ]
    resources = [
      "arn:aws:events:*:*:rule/AwsDataLifecycleRule.managed-cwe.*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "dlm" {
  role       = aws_iam_role.dlm.name
  policy_arn = aws_iam_policy.dlm.arn
}


# ===============================================================================
# AWS IAM Policy to enforce MFA (for IAM Users and IAM Groups)
# ===============================================================================
resource "aws_iam_policy" "enforce_mfa" {
  name        = "${local.project}-common-iam-enforce-mfa-policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.enforce_mfa.json
  description = "AWS IAM Policy to enforce MFA devices authentication."

  tags = {
    Name = "${local.project}-common-iam-enforce-mfa-policy"
  }
}

data "aws_iam_policy_document" "enforce_mfa" {
  statement {
    sid    = "EnforceMFA"
    effect = "Deny"
    not_actions = [
      "iam:ListVirtualMFADevices",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
      "iam:ChangePassword",
      "iam:ReadOnlyAccess",
    ]
    resources = [
      "*",
    ]
    condition {
      test     = "BoolIfExists"
      variable = "aws:MultiFactorAuthPresent"
      values = [
        "false",
      ]
    }
  }

  statement {
    sid    = "ExcludeTerraformStateFilesAccess"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "arn:aws:s3:::v-terraform-rag-template-${local.env}",
      "arn:aws:s3:::v-terraform-rag-template-${local.env}/*",
    ]
  }
}


# ===============================================================================
# AWS IAM Policy to revoke AWS Cloud9 access (for IAM Users and IAM Groups)
# ===============================================================================
resource "aws_iam_policy" "deny_cloud9_access" {
  name        = "${local.project}-common-iam-deny-cloud9-access-policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.deny_cloud9_access.json
  description = "AWS IAM Policy to revoke AWS Cloud9 access."

  tags = {
    Name = "${local.project}-common-iam-deny-cloud9-access-policy"
  }
}

data "aws_iam_policy_document" "deny_cloud9_access" {
  statement {
    sid    = "DenyCloud9Access"
    effect = "Deny"
    actions = [
      "cloud9:*",
    ]
    resources = [
      "*",
    ]
  }
}


# ===============================================================================
# AWS IAM Policy to allow MFA devices configure (for IAM Users and IAM Groups)
# ===============================================================================
resource "aws_iam_policy" "allow_mfa_configure" {
  name        = "${local.project}-common-iam-allow-mfa-configure-policy"
  path        = "/"
  policy      = data.aws_iam_policy_document.allow_mfa_configure.json
  description = "AWS IAM Policy to allow MFA devices configure."
  tags = {
    Name = "${local.project}-common-iam-allow-mfa-configure-policy"
  }
}

data "aws_iam_policy_document" "allow_mfa_configure" {
  statement {
    sid    = "AllowMFAConfigure"
    effect = "Allow"
    actions = [
      "iam:ListVirtualMFADevices",
      "iam:CreateVirtualMFADevice",
      "iam:DeleteVirtualMFADevice",
      "iam:DeactivateMFADevice",
      "iam:EnableMFADevice",
      "iam:ResyncMFADevice",
      "iam:ListMFADevices",
      "iam:ChangePassword",
    ]
    resources = [
      "*",
    ]
  }
}
