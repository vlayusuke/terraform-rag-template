# ===============================================================================
# AWS KMS for Application
# ===============================================================================
resource "aws_kms_key" "application" {
  description         = "${local.project}-${local.env}-kms-application-key"
  enable_key_rotation = true

  tags = {
    Name = "${local.project}-${local.env}-kms-application-key"
  }
}


# ===============================================================================
# AWS KMS for Amazon Aurora Serverless v2
# ===============================================================================
resource "aws_kms_key" "aurora" {
  description             = "${local.project}-${local.env}-kms-aurora-key"
  enable_key_rotation     = true
  key_usage               = "ENCRYPT_DECRYPT"
  deletion_window_in_days = 7

  tags = {
    Name = "${local.project}-${local.env}-kms-aurora-key"
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
