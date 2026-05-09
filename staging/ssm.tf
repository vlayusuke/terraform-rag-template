# ===============================================================================
# AWS SSM Parameters for PostgreSQL
# ===============================================================================
resource "aws_ssm_parameter" "postgresql_username" {
  name        = "/${local.project}/${local.env}/postgresql-username"
  description = "The parameter for ${local.project}-${local.env} PostgreSQL username"
  key_id      = aws_kms_key.aurora.key_id
  type        = "SecureString"
  value       = local.rds_postgres_role_name

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-ssm-postgresql-username"
  }
}

resource "aws_ssm_parameter" "postgresql_password" {
  name        = "/${local.project}/${local.env}/postgresql-password"
  description = "The parameter for ${local.project}-${local.env} PostgreSQL password"
  key_id      = aws_kms_key.aurora.key_id
  type        = "SecureString"
  value       = "PleaseChangePassword1234"

  lifecycle {
    ignore_changes = [
      value,
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-ssm-postgresql-password"
  }
}
