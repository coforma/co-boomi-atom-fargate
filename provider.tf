terraform {
  required_version = "< 1.6"
  backend "s3" {
    bucket         = "co-boomi-atom-tfstate"
    encrypt        = true
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "co-boomi-atom-dynamo-lock"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.25.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      Application = var.application
      Owner       = var.owner
    }
  }
}
