# ===============================================================================
# Amazon CloudWatch Synthetics Group
# ===============================================================================
resource "aws_synthetics_group" "main" {
  name = "${local.project}-${local.env}-cwt-syn-group"

  tags = {
    Name = "${local.project}-${local.env}-cwt-syn-group"
  }
}

resource "aws_synthetics_group_association" "check_request_api" {
  group_name = aws_synthetics_group.main.name
  canary_arn = aws_synthetics_canary.check_request_api.arn
}


# ===============================================================================
# Amazon CloudWatch Synthetics Canary for Check Request API Monitoring
# ===============================================================================
resource "aws_synthetics_canary" "check_request_api" {
  name                 = "${local.project}-${local.env}-cwt-syn-check-request-api"
  artifact_s3_location = aws_s3_bucket.synthetics_artifacts.arn
  execution_role_arn   = aws_iam_role.cloudwatch_synthetics.arn
  handler              = "canary_check_request_api.function.canary_handler"
  runtime_version      = "syn-python-selenium-11.0"
  zip_file             = "artifacts/canary-check-request-api.zip"

  schedule {
    expression = "rate(5 minutes)"
  }

  artifact_config {
    s3_encryption {
      encryption_mode = "SSE_KMS"
      kms_key_arn     = aws_kms_key.synthetics.arn
    }
  }

  tags = {
    Name = "${local.project}-${local.env}-cwt-syn-check-request-api"
  }
}

data "archive_file" "canary_check_request_api" {
  type        = "zip"
  source_dir  = "${path.cwd}/files/canary/canary-check-request-api"
  output_path = "${path.module}/artifacts/canary-check-request-api.zip"
}
