resource "aws_ecs_task_definition" "task_definition" {
  family = var.application
  container_definitions = jsonencode([{
    environment : [
      {
        name  = "BOOMI_ATOMNAME"
        value = var.atom_name
      },
      {
        name  = "BOOMI_ENVIRONMENTID"
        value = var.boomi_environment_id
      },
      {
        name  = "ATOM_LOCALHOSTID"
        value = var.atom_name
      }
    ],
    secrets : [
      {
        valueFrom : module.secrets_manager.secret_arn,
        name : "INSTALL_TOKEN"
      }
    ]
    name      = local.container_name
    image     = "boomi/atom:${var.atom_version}"
    essential = true,
    portMappings = [
      {
        containerPort = var.container_port
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.logs.name
        "awslogs-region"        = var.aws_region
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

# Create security group for the task using the extra security group egress rules
resource "aws_security_group" "task_security_group" {
  name        = "${var.application}-task-sg"
  description = "Security group for the Atom ECS task"
  vpc_id      = module.vpc.vpc_id

  # dynamic egress
  dynamic "egress" {
    for_each = var.atom_security_group_egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_ecs_service" "service" {
  cluster         = module.ecs.cluster_id
  desired_count   = 1
  launch_type     = "FARGATE"
  name            = "${var.application}-service"
  task_definition = aws_ecs_task_definition.task_definition.arn

  lifecycle {
    ignore_changes = [desired_count] # Ignore changes to desired count
  }

  network_configuration {
    security_groups  = [module.vpc.default_security_group_id, aws_security_group.task_security_group.id]
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
  }
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.application}"
  retention_in_days = var.retention_in_days
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.application}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.application}-iam-role"
    Environment = var.environment
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    effect = "Allow"
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    effect    = "Allow"
    resources = ["${aws_cloudwatch_log_group.logs.arn}:*"]
  }
}

resource "aws_iam_policy" "task_permissions" {
  name        = "${var.application}-task-permissions"
  description = "Policy to allow ecs task execution role to write to cloudwatch logs"
  policy      = data.aws_iam_policy_document.task_permissions.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_log_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.task_permissions.arn
}

// this policy doc should give the ecs task execution role read access to the secrets manager secret 
data "aws_iam_policy_document" "ssm_policy" {
  statement {
    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetSecretValue",
    ]
    resources = [module.secrets_manager.secret_arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ssm_policy" {
  name        = "${var.application}-ssm-policy"
  description = "Policy to allow ecs task execution role to read secrets manager secret"
  policy      = data.aws_iam_policy_document.ssm_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_ssm_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}
