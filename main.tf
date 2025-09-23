# main.tf

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Backend configuration for remote state
  backend "s3" {
     bucket = "rdof-terraform-state"
     region = "us-east-1"
     key     = "terraform/${terraform.workspace}/terraform.tfstate"
     encrypt = true
   }
}

# Local values for environment-specific configurations
locals {
  account_ids = {
    prod    = var.prod_account_id
    staging = var.staging_account_id
    dev     = var.dev_account_id
  }

  # Determine which role to assume based on workspace
  assume_role_arn = "arn:aws:iam::${local.account_ids[terraform.workspace]}:role/terraform/TerraformCrossAccountRole"

  # External ID for additional security
  external_id = "terraform-cross-account-${local.account_ids[terraform.workspace]}"

  # Check if we should use assume role (only if USE_ASSUME_ROLE env var is set to "true")
  use_assume_role = var.use_assume_role

  # Environment-specific configurations
  environment_config = {
    prod = {
      versioning = true
      encryption = true
    }
    staging = {
      versioning = true
      encryption = false
    }
    dev = {
      versioning = false
      encryption = false
    }
  }

  current_config = local.environment_config[terraform.workspace]
  current_buckets = var.bucket_names[terraform.workspace]
}

# Provider configuration - conditional assume role
provider "aws" {
  region = var.region

  # Only assume role if use_assume_role is true
  dynamic "assume_role" {
    for_each = local.use_assume_role ? [1] : []
    content {
      role_arn    = local.assume_role_arn
      external_id = local.external_id
    }
  }

  default_tags {
    tags = {
      Environment   = terraform.workspace
      ManagedBy     = "Terraform"
      Project       = "MultiAccountInfra"
    }
  }
}
