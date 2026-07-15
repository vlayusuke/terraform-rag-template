# ===============================================================================
# AWS KMS for Application
# ===============================================================================
resource "aws_kms_key" "application" {
  description             = "${local.project}-${local.env}-kms-application-key"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    Name = "${local.project}-${local.env}-kms-application-key"
  }
}


# ===============================================================================
# AWS KMS Key Policy for Application
# ===============================================================================
resource "aws_kms_key_policy" "application" {
  key_id = aws_kms_key.application.key_id
  policy = data.aws_iam_policy_document.application_kms_policy.json
}

data "aws_iam_policy_document" "application_kms_policy" {
  statement {
    sid    = "ApplicationKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.application.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "secretsmanager.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      aws_kms_key.application.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}


# ===============================================================================
# AWS KMS for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_kms_key" "aurora" {
  description             = "${local.project}-${local.env}-kms-aur-key"
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7

  tags = {
    Name = "${local.project}-${local.env}-kms-aur-key"
  }
}


# ===============================================================================
# AWS KMS Key Policy for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_kms_key_policy" "aurora" {
  key_id = aws_kms_key.aurora.key_id
  policy = data.aws_iam_policy_document.aurora_kms_policy.json
}

data "aws_iam_policy_document" "aurora_kms_policy" {
  statement {
    sid    = "AuroraKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.aurora.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "rds.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      aws_kms_key.aurora.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}


# ===============================================================================
# AWS KMS for Amazon EBS
# ===============================================================================
resource "aws_kms_key" "ebs" {
  description             = "${local.project}-${local.env}-kms-ebs-key"
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7

  tags = {
    Name = "${local.project}-${local.env}-kms-ebs-key"
  }
}


# ===============================================================================
# AWS KMS Key Policy for Amazon EBS
# ===============================================================================
resource "aws_kms_key_policy" "ebs" {
  key_id = aws_kms_key.ebs.key_id
  policy = data.aws_iam_policy_document.ebs_kms_policy.json
}

data "aws_iam_policy_document" "ebs_kms_policy" {
  statement {
    sid    = "EBSKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.ebs.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "ebs.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      aws_kms_key.ebs.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}


# ===============================================================================
# AWS KMS for Amazon Cloudwatch Synthetics
# ===============================================================================
resource "aws_kms_key" "synthetics" {
  description             = "${local.project}-${local.env}-kms-synthetics-key"
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7

  tags = {
    Name = "${local.project}-${local.env}-kms-synthetics-key"
  }
}


# ===============================================================================
# AWS KMS Key Policy for Amazon Cloudwatch Synthetics
# ===============================================================================
resource "aws_kms_key_policy" "synthetics" {
  key_id = aws_kms_key.synthetics.key_id
  policy = data.aws_iam_policy_document.synthetics_kms_policy.json
}

data "aws_iam_policy_document" "synthetics_kms_policy" {
  statement {
    sid    = "SyntheticsKMS"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      aws_kms_key.synthetics.arn,
    ]
    principals {
      type = "Service"
      identifiers = [
        "synthetics.amazonaws.com",
      ]
    }
  }

  statement {
    sid    = "AllowAccountAccess"
    effect = "Allow"
    actions = [
      "kms:*",
    ]
    resources = [
      aws_kms_key.synthetics.arn,
    ]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
  }
}
