# ===============================================================================
# AWS Secrets Manager for PostgreSQL Password
# ===============================================================================
resource "aws_secretsmanager_secret" "postgresql_app_password" {
  name        = "/${local.project}/${local.env}/app_postgresql_password"
  description = "The secret for PostgreSQL Password used by the application in ${local.env} environment."
}

resource "aws_secretsmanager_secret_version" "postgresql_app_password" {
  secret_id = aws_secretsmanager_secret.postgresql_app_password.id
  secret_string = jsonencode({
    username = local.rds_postgres_role_name
    password = "PleaseChangePassword1234"
  })

  lifecycle {
    ignore_changes = [
      secret_string,
    ]
  }
}
