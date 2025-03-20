terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.86.0"
        }
        random = {
            source = "hashicorp/random"
            version = "~> 3.0"
        }
        local = {
            source = "hashicorp/local"
            version = "~> 2.5"
        }
        tls = {
            source = "hashicorp/tls"
            version = "~> 4.0.6"
        }
    }
    required_version = ">= 1.2.0"
}

# general settings
variable "environment" {
    type = string
    default = "prod"
}

variable "region" {
    type = string
    default = "us-east-1"
}

provider "aws" {
    region = var.region
}

resource "random_id" "random_identifier" {
    byte_length = 2 # random 4 character hex string
}

locals {
    tag = "sample-${var.environment}-${random_id.random_identifier.hex}"
}
