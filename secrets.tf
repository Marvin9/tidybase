resource "aws_secretsmanager_secret" "tidybase_secret" {
  name                    = var.tidybase_secret_name
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "tidybase_values" {
  secret_id = aws_secretsmanager_secret.tidybase_secret.id
  secret_string = jsonencode({
    ADMIN_EMAIL    = var.ADMIN_EMAIL
    ADMIN_PASSWORD = var.ADMIN_PASSWORD
  })
}
