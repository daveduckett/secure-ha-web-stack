resource "aws_secretsmanager_secret" "secrets_vault" {
  name = "secrets_vault_v4"
}

resource "aws_secretsmanager_secret_version" "secrets_version" {
  secret_id             = aws_secretsmanager_secret.secrets_vault.id
  secret_string = jsonencode({
    username    = var.credentials_username_password.username
    password    = var.credentials_username_password.password
    engine      = "mysql"
    host        = aws_db_instance.default.address
    port        = 3306
    db_name     = aws_db_instance.default.db_name
  })
}