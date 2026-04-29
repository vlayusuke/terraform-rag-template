data "aws_elb_service_account" "alb_logs" {}


# ===============================================================================
# Amazon S3 Bucket for RAG Document
# ===============================================================================
resource "aws_s3_bucket" "rag_document" {
  bucket = "${local.project}-${local.env}-s3-rag-document-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-rag-document-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.rag_document,
  ]
}

resource "aws_s3_bucket_public_access_block" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "rag_document" {
  bucket = aws_s3_bucket.rag_document.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.rag_document,
  ]
}

resource "aws_s3_bucket_logging" "rag_document" {
  bucket        = aws_s3_bucket.rag_document.id
  target_bucket = aws_s3_bucket.s3_server_access_logs.id
  target_prefix = "${aws_s3_bucket.rag_document.id}/"
}

resource "aws_s3_bucket_policy" "rag_document" {
  bucket = aws_s3_bucket.rag_document.id
  policy = data.aws_iam_policy_document.rag_document.json
}

data "aws_iam_policy_document" "rag_document" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.rag_document.arn,
      "${aws_s3_bucket.rag_document.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for VPC flow log
# ===============================================================================
resource "aws_s3_bucket" "vpc_flow_log" {
  bucket = "${local.project}-${local.env}-s3-vpc-flow-log-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-vpc-flow-log-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.vpc_flow_log,
  ]
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.vpc_flow_log,
  ]
}

resource "aws_s3_bucket_policy" "vpc_flow_log" {
  bucket = aws_s3_bucket.vpc_flow_log.id
  policy = data.aws_iam_policy_document.vpc_flow_log.json
}

data "aws_iam_policy_document" "vpc_flow_log" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.vpc_flow_log.arn,
      "${aws_s3_bucket.vpc_flow_log.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for AWS Lambda logs
# ===============================================================================
resource "aws_s3_bucket" "lambda_logs" {
  bucket = "${local.project}-${local.env}-s3-lambda-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-lambda-logs-bucket"
  }
}

resource "aws_s3_object" "prefix_lambda" {
  for_each = local.lambda_functions
  bucket   = aws_s3_bucket.lambda_logs.bucket
  key      = "${each.key}/"
  acl      = "private"

  tags = {
    Name = "${local.project}-${local.env}-s3-prefix-lambda-${each.key}"
  }
}

resource "aws_s3_bucket_ownership_controls" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.lambda_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.lambda_logs,
  ]
}

resource "aws_s3_bucket_policy" "lambda_logs" {
  bucket = aws_s3_bucket.lambda_logs.id
  policy = data.aws_iam_policy_document.lambda_logs.json
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.lambda_logs.arn,
      "${aws_s3_bucket.lambda_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon Aurora logs
# ===============================================================================
resource "aws_s3_bucket" "aurora_logs" {
  bucket = "${local.project}-${local.env}-s3-aurora-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-aurora-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.aurora_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.aurora_logs,
  ]
}

resource "aws_s3_bucket_policy" "aurora_logs" {
  bucket = aws_s3_bucket.aurora_logs.id
  policy = data.aws_iam_policy_document.aurora_logs.json
}

data "aws_iam_policy_document" "aurora_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.aurora_logs.arn,
      "${aws_s3_bucket.aurora_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon Bedrock Knowledge base logs
# ===============================================================================
resource "aws_s3_bucket" "bedrock_logs" {
  bucket = "${local.project}-${local.env}-s3-brk-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-brk-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.bedrock_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.bedrock_logs,
  ]
}

resource "aws_s3_bucket_policy" "bedrock_logs" {
  bucket = aws_s3_bucket.bedrock_logs.id
  policy = data.aws_iam_policy_document.bedrock_logs.json
}

data "aws_iam_policy_document" "bedrock_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.bedrock_logs.arn,
      "${aws_s3_bucket.bedrock_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon SNS logs
# ===============================================================================
resource "aws_s3_bucket" "sns_logs" {
  bucket = "${local.project}-${local.env}-s3-sns-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-sns-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.sns_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.sns_logs,
  ]
}

resource "aws_s3_bucket_policy" "sns_logs" {
  bucket = aws_s3_bucket.sns_logs.id
  policy = data.aws_iam_policy_document.sns_logs.json
}

data "aws_iam_policy_document" "sns_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.sns_logs.arn,
      "${aws_s3_bucket.sns_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon SNS event logs
# ===============================================================================
resource "aws_s3_bucket" "sns_event_logs" {
  bucket = "${local.project}-${local.env}-s3-sns-event-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-sns-event-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.sns_event_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "sns_event_logs" {
  bucket                  = aws_s3_bucket.sns_event_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.sns_event_logs,
  ]
}

resource "aws_s3_bucket_policy" "sns_event_logs" {
  bucket = aws_s3_bucket.sns_event_logs.id
  policy = data.aws_iam_policy_document.sns_event_logs.json
}

data "aws_iam_policy_document" "sns_event_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.sns_event_logs.arn,
      "${aws_s3_bucket.sns_event_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon CloudFront logs
# ===============================================================================
resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${local.project}-${local.env}-s3-cloudfront-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-cloudfront-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.cloudfront_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.cloudfront_logs,
  ]
}

resource "aws_s3_bucket_policy" "cloudfront_logs" {
  bucket = aws_s3_bucket.cloudfront_logs.id
  policy = data.aws_iam_policy_document.cloudfront_logs.json
}

data "aws_iam_policy_document" "cloudfront_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.cloudfront_logs.arn,
      "${aws_s3_bucket.cloudfront_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for AWS WAFv2 Logs
# ===============================================================================
resource "aws_s3_bucket" "waf_logs" {
  bucket = "aws-waf-logs-${local.project}-${local.env}-s3-waf-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-waf-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  acl    = "log-delivery-write"

  depends_on = [
    aws_s3_bucket_ownership_controls.waf_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.waf_logs,
  ]
}

resource "aws_s3_bucket_policy" "waf_logs" {
  bucket = aws_s3_bucket.waf_logs.id
  policy = data.aws_iam_policy_document.waf_logs.json
}

data "aws_iam_policy_document" "waf_logs" {
  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.waf_logs.arn,
      "${aws_s3_bucket.waf_logs.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }

  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.waf_logs.arn}/*"
    ]

    principals {
      type = "Service"
      identifiers = [
        "logging.s3.amazonaws.com",
        "waf.amazonaws.com",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon EC2 Bastion
# ===============================================================================
resource "aws_s3_bucket" "bastion" {
  bucket = "${local.project}-${local.env}-s3-bastion-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-bastion-bucket"
  }
}

resource "aws_s3_object" "prefix_bastion_logs" {
  bucket = aws_s3_bucket.bastion.bucket
  key    = "bastion-logs/"
  acl    = "private"

  tags = {
    Name = "${local.project}-${local.env}-s3-prefix-bastion-logs"
  }
}

resource "aws_s3_bucket_ownership_controls" "bastion" {
  bucket = aws_s3_bucket.bastion.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "bastion" {
  bucket = aws_s3_bucket.bastion.id
  acl    = "private"

  depends_on = [
    aws_s3_bucket_ownership_controls.bastion,
  ]
}

resource "aws_s3_bucket_public_access_block" "bastion" {
  bucket = aws_s3_bucket.bastion.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bastion" {
  bucket = aws_s3_bucket.bastion.bucket

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "bastion" {
  bucket = aws_s3_bucket.bastion.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "bastion_sh" {
  bucket                 = aws_s3_bucket.bastion.id
  key                    = "bastion.sh"
  content                = local.bastion_sh
  server_side_encryption = "AES256"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_object" "install_iam_ssh" {
  bucket                 = aws_s3_bucket.bastion.id
  key                    = "install_iam_ssh.sh"
  content                = local.install_iam_ssh
  server_side_encryption = "AES256"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_object" "aws_ec2_ssh_conf" {
  bucket                 = aws_s3_bucket.bastion.id
  key                    = "aws-ec2-ssh.conf"
  content                = local.aws_ec2_ssh_conf
  server_side_encryption = "AES256"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_object" "bastion_cloudwatch_agent" {
  bucket                 = aws_s3_bucket.bastion.id
  key                    = "amazon-cloudwatch-agent.json"
  content                = local.bastion_cloudwatch_agent
  server_side_encryption = "AES256"

  lifecycle {
    prevent_destroy = false
  }
}

locals {
  bastion_sh = templatefile(
    "src/files/startup_scripts/bastion.sh",
    {
      bastion_bucket = aws_s3_bucket.bastion.id
    }
  )

  install_iam_ssh = templatefile(
    "src/files/iam_ssh/install_iam_ssh.sh",
    {
      bucket = aws_s3_bucket.bastion.id
    }
  )

  aws_ec2_ssh_conf = templatefile(
    "src/files/iam_ssh/aws-ec2-ssh.conf",
    {
      project    = local.project
      account-id = data.aws_caller_identity.current.account_id
    }
  )

  bastion_cloudwatch_agent = templatefile(
    "src/files/bastion/amazon-cloudwatch-agent.json",
    {
      log_group_name = aws_cloudwatch_log_group.bastion.name
    }
  )
}


# ================================================================================
# Amazon S3 Bucket for Source Code Backup (Osaka)
# ================================================================================
resource "aws_s3_bucket" "source_backup_osaka" {
  bucket   = "${local.project}-${local.env}-s3-github-backup-osaka-bucket"
  provider = aws.osaka

  tags = {
    Name = "${local.project}-${local.env}-s3-github-backup-osaka-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  acl      = "private"
  provider = aws.osaka

  depends_on = [
    aws_s3_bucket_ownership_controls.source_backup_osaka,
  ]
}

resource "aws_s3_bucket_public_access_block" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.bucket
  provider = aws.osaka

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  provider = aws.osaka

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "source_backup_osaka" {
  bucket   = aws_s3_bucket.source_backup_osaka.id
  policy   = data.aws_iam_policy_document.source_backup_osaka.json
  provider = aws.osaka
}

data "aws_iam_policy_document" "source_backup_osaka" {
  provider = aws.osaka

  statement {
    sid    = "EnforceSSL"
    effect = "Deny"
    actions = [
      "s3:*",
    ]
    resources = [
      aws_s3_bucket.source_backup_osaka.arn,
      "${aws_s3_bucket.source_backup_osaka.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }

    principals {
      type = "AWS"
      identifiers = [
        "*",
      ]
    }
  }
}


# ===============================================================================
# Amazon S3 Bucket for Amazon S3 Server Access Logs
# ===============================================================================
resource "aws_s3_bucket" "s3_server_access_logs" {
  bucket = "${local.project}-${local.env}-s3-server-access-logs-bucket"

  tags = {
    Name = "${local.project}-${local.env}-s3-server-access-logs-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id
  acl    = "log-delivery-write"

  depends_on = [
    aws_s3_bucket_ownership_controls.s3_server_access_logs,
  ]
}

resource "aws_s3_bucket_public_access_block" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id

  rule {
    blocked_encryption_types = [
      "SSE-C"
    ]
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = false
  }
}

resource "aws_s3_bucket_versioning" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id

  rule {
    id     = "transition-and-delete-object"
    status = "Enabled"

    filter {
      object_size_greater_than = 0
    }

    transition {
      days          = local.transition_days
      storage_class = "GLACIER"
    }

    expiration {
      days = local.expire_days
    }

    noncurrent_version_transition {
      noncurrent_days = local.transition_days
      storage_class   = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = local.expire_days
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.s3_server_access_logs,
  ]
}

resource "aws_s3_bucket_policy" "s3_server_access_logs" {
  bucket = aws_s3_bucket.s3_server_access_logs.id
  policy = data.aws_iam_policy_document.s3_server_access_logs.json
}

data "aws_iam_policy_document" "s3_server_access_logs" {
  statement {
    sid    = "S3ServerAccessLogsPolicy"
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.s3_server_access_logs.arn}/*",
    ]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values = [
        aws_s3_bucket.rag_document.arn,
      ]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values = [
        "${data.aws_caller_identity.current.account_id}",
      ]
    }

    principals {
      type = "Service"
      identifiers = [
        "logging.s3.amazonaws.com",
      ]
    }
  }
}
