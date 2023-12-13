# create a variable for the region
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

# create a variable for the application name
variable "application" {
  description = "The name of the application"
  default     = "co-boomi-atom"
  type        = string
}

variable "atom_name" {
  description = "The name of the atom"
  default     = "coforma-atom-1"
  type        = string
}

# create a variable for the environment
variable "environment" {
  description = "The environment to deploy to"
  default     = "prod"
  type        = string
}

# create a variable for the owner
variable "owner" {
  description = "The owner of the application"
  default     = "devsecops"
  type        = string
}

# Container variables
variable "container_port" {
  description = "The port of the container"
  default     = 9090
  type        = number
}

variable "atom_version" {
  description = "The version of the atom"
  default     = "4.3.5"
  type        = string
}

# Container secrets
variable "boomi_username" {
  description = "The username for the boomi platform"
  sensitive   = true
  type        = string
}

variable "boomi_auth_token" {
  description = "The auth token for the boomi platform"
  sensitive   = true
  type        = string
}

variable "boomi_account_id" {
  description = "The account ID for the boomi platform"
  sensitive   = true
  type        = string
}

variable "boomi_environment_id" {
  description = "The environment ID of the atom is to be attached"
  default     = ""
  type        = string
}

# Network variables
variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.1.0.0/24"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR block for the subnet"
  default     = ["10.1.0.0/27", "10.1.0.32/27"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "The CIDR block for the subnet"
  default     = ["10.1.0.64/27", "10.1.0.96/27"]
}

# Extra security group egress rules
variable "atom_security_group_egress" {
  type = list(object({
    from_port   = number
    to_port     = number
    description = string
    protocol    = string
    cidr_blocks = list(string)
  }))
  description = "Atom security group egress rules"
  default = [
    {
      from_port   = 31001
      to_port     = 31001
      description = "Unanet traffic"
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

variable "retention_in_days" {
  description = "The number of days to retain logs"
  default     = 7
  type        = number
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs               = slice(data.aws_availability_zones.available.names, 0, 3)
  container_name    = "${var.application}-ct"
  function_name     = "${var.application}-secret-install-lambda"
  secret_prefix     = "/${var.application}/${var.environment}"
  token_secret_name = "${local.secret_prefix}/boomi-install-token"

  # Create subnet names from CIDR blocks variable
  private_subnet_names = [for i in range(length(var.private_subnet_cidrs)) : "${var.application}-private-subnet-${i}"]
  public_subnet_names  = [for i in range(length(var.public_subnet_cidrs)) : "${var.application}-public-subnet-${i}"]
}
