terraform {
  required_version = "1.5.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.52.0"
    }
  }
}

provider "aws" {}
