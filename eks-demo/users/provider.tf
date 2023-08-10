provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      team = "DevOps"
    }
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}
