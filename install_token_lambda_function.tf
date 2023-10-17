module "secrets_manager" {
  source  = "terraform-aws-modules/secrets-manager/aws"
  version = "~> 1.1.1"

  # Secret
  name                    = local.token_secret_name
  description             = "Rotated example Secrets Manager secret"
  recovery_window_in_days = 0

  # Policy
  create_policy       = true
  block_public_policy = true
  policy_statements = {
    lambda = {
      sid = "LambdaReadWrite"
      principals = [{
        type        = "AWS"
        identifiers = [module.lambda.lambda_role_arn]
      }]
      actions = [
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage",
      ]
      resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${local.token_secret_name}"]
    }
  }

  # Version
  ignore_secret_changes = true
  secret_string         = "1234"

  # Rotation
  enable_rotation     = true
  rotation_lambda_arn = module.lambda.lambda_function_arn
  rotation_rules = {
    # This should be more sensible in production
    schedule_expression = "rate(12 hours)"
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
      "secretsmanager:PutSecretValue",
      "secretsmanager:UpdateSecretVersionStage",
    ]
    resources = [module.secrets_manager.secret_arn]
    effect    = "Allow"
  }
}

module "lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 6.0.1"

  function_name = local.function_name
  description   = "Example Secrets Manager secret rotation lambda function"

  environment_variables = {
    BOOMI_USERNAME   = aws_ssm_parameter.boomi_username.value
    BOOMI_AUTH_TOKEN = aws_ssm_parameter.boomi_auth_token.value
    BOOMI_ACCOUNT_ID = aws_ssm_parameter.boomi_account_id.value
  }

  handler     = "rotate_install_token.lambda_handler"
  runtime     = "python3.11"
  timeout     = 60
  memory_size = 512

  source_path = [
    "${path.module}/lambda/rotate_install_token.py",
    "${path.module}/lambda/package/",
  ]

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda.json

  publish = true
  allowed_triggers = {
    secrets = {
      principal = "secretsmanager.amazonaws.com"
    }
  }

  cloudwatch_logs_retention_in_days = var.retention_in_days
}