data "aws_caller_identity" "current" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.4.0"

  azs                    = local.azs
  cidr                   = var.vpc_cidr
  create_igw             = true # Expose public subnetworks to the Internet
  enable_nat_gateway     = true # Hide private subnetworks behind NAT Gateway
  private_subnets        = var.private_subnet_cidrs
  private_subnet_names   = local.private_subnet_names
  public_subnets         = var.public_subnet_cidrs
  public_subnet_names    = local.public_subnet_names
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  name                        = "${var.application}-vpc"
  default_vpc_name            = "${var.application}-vpc"
  default_network_acl_name    = "${var.application}-vpc-nacl"
  default_route_table_name    = "${var.application}-vpc-rt"
  default_security_group_name = "${var.application}-vpc-sg"
  default_security_group_egress = [
    {
      from_port   = 80
      to_port     = 80
      description = "HTTP traffic"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    },
    {
      from_port   = 443
      to_port     = 443
      description = "HTTPS traffic"
      protocol    = "tcp"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.9.0"

  cluster_name = "${var.application}-cluster"
}
