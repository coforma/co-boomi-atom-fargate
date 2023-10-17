resource "aws_ssm_parameter" "boomi_username" {
  name        = "${local.secret_prefix}/username"
  description = "Boomi username for retrieving an install token from Boomi"
  type        = "SecureString"
  value       = var.boomi_username

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "boomi_auth_token" {
  name        = "${local.secret_prefix}/auth-token"
  description = "API Token for retrieving an install token from Boomi"
  type        = "SecureString"
  value       = var.boomi_auth_token

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "boomi_account_id" {
  name        = "${local.secret_prefix}/account-id"
  description = "Boomi account ID for retrieving an install token from Boomi"
  type        = "SecureString"
  value       = var.boomi_account_id

  lifecycle {
    ignore_changes = [value]
  }
}
