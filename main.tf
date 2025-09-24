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
    bucket = "rdof-terraform-state-prod"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
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

# S3 buckets based on workspace and bucket names array
resource "aws_s3_bucket" "app_buckets" {
  for_each = toset(local.current_buckets)
  bucket   = each.value

  tags = {
    Name        = each.value
    Environment = terraform.workspace
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "app_buckets" {
  for_each = local.current_config.versioning ? toset(local.current_buckets) : toset([])
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_buckets" {
  for_each = local.current_config.encryption ? toset(local.current_buckets) : toset([])
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_buckets" {
  for_each = toset(local.current_buckets)
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Cross-account bucket policies (only for prod workspace)
resource "aws_s3_bucket_policy" "cross_account_access" {
  for_each = terraform.workspace == "prod" ? toset(local.current_buckets) : toset([])
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [
            # Allow entire staging and dev accounts access
            "arn:aws:iam::${var.staging_account_id}:root",
            "arn:aws:iam::${var.dev_account_id}:root",
            # Also allow the specific cross-account roles
            "arn:aws:iam::${var.staging_account_id}:role/terraform/TerraformCrossAccountRole",
            "arn:aws:iam::${var.dev_account_id}:role/terraform/TerraformCrossAccountRole"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl"
        ]
        Resource = [
          aws_s3_bucket.app_buckets[each.key].arn,
          "${aws_s3_bucket.app_buckets[each.key].arn}/*"
        ]
      }
    ]
  })
}

# Terraform state backend bucket policy (only in prod workspace)
resource "aws_s3_bucket_policy" "terraform_state_backend_cross_account" {
  count  = terraform.workspace == "prod" ? 1 : 0
  bucket = var.terraform_state_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateBackendCrossAccount"
        Effect = "Allow"
        Principal = {
          AWS = [
            # Allow staging and dev accounts full access to state bucket
            "arn:aws:iam::${var.staging_account_id}:root",
            "arn:aws:iam::${var.dev_account_id}:root",
            # Allow specific cross-account roles
            "arn:aws:iam::${var.staging_account_id}:role/terraform/TerraformCrossAccountRole",
            "arn:aws:iam::${var.dev_account_id}:role/terraform/TerraformCrossAccountRole",
            # Allow prod service account direct access
            "arn:aws:iam::${var.prod_account_id}:user/terraform/prod-terraform-service-account"
          ]
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:GetObjectVersion",
          "s3:ListBucketVersions"
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket_name}",
          "arn:aws:s3:::${var.terraform_state_bucket_name}/*"
        ]
      },
      {
        Sid    = "TerraformStateLockTable"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.staging_account_id}:root",
            "arn:aws:iam::${var.dev_account_id}:root",
            "arn:aws:iam::${var.staging_account_id}:role/terraform/TerraformCrossAccountRole",
            "arn:aws:iam::${var.dev_account_id}:role/terraform/TerraformCrossAccountRole",
            "arn:aws:iam::${var.prod_account_id}:user/terraform/prod-terraform-service-account"
          ]
        }
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          "arn:aws:dynamodb:${var.region}:${var.prod_account_id}:table/${var.terraform_state_lock_table_name}"
        ]
      }
    ]
  })
}

# Optional: Create additional cross-account IAM policies for more granular access
resource "aws_iam_policy" "cross_account_s3_access" {
  count = terraform.workspace == "prod" ? 1 : 0

  name        = "CrossAccountS3Access"
  path        = "/terraform/"
  description = "Policy for cross-account S3 access to prod buckets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          for bucket_name in local.current_buckets : [
            "arn:aws:s3:::${bucket_name}",
            "arn:aws:s3:::${bucket_name}/*"
          ]
        ]
      }
    ]
  })

  tags = {
    Environment = "prod"
    Purpose     = "Cross-account S3 access"
  }
}