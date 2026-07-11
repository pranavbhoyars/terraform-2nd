terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      
    }
  }
  # It is highly recommended to configure a remote S3 backend here for shared state
}

provider "aws" {
  region = var.aws_region
}

module "infrastructure" {
  source   = "./modules/vpc_ec2"
  region   = var.aws_region
}
