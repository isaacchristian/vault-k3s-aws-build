terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      version = "5.31.0"
      source  = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = var.region
}