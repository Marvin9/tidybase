terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  backend "s3" {
    bucket = "cdktf-state-cloud-architect-mayur"
    key    = "infra"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
}
