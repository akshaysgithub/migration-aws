# iam.tf - IAM resources for PROD account only
# This creates the prod service account and prod cross-account role

# Local values for IAM setup (only for prod)
locals {
  # Only create prod IAM resources in prod workspace
  create_prod_iam = terraform.workspace == "prod"
}

# Prod Service Account (IAM User) - only in prod workspace
resource "aws_iam_user" "prod_service_account" {
  count = local.create_prod_iam ? 1 : 0

  name = "prod-terraform-service-account"
  path = "/terraform/"

  tags = {
    Purpose = "Terraform multi-account management"
    Environment = "prod"
  }
}

# Access keys for the service account - only in prod workspace
resource "aws_iam_access_key" "prod_service_account" {
  count = local.create_prod_iam ? 1 : 0

  user = aws_iam_user.prod_service_account[0].name
}

# Policy for the prod service account to assume cross-account roles - only in prod workspace
resource "aws_iam_user_policy" "prod_service_account_policy" {
  count = local.create_prod_iam ? 1 : 0

  name = "CrossAccountAssumeRolePolicy"
  user = aws_iam_user.prod_service_account[0].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::${var.staging_account_id}:role/terraform/TerraformCrossAccountRole",
          "arn:aws:iam::${var.dev_account_id}:role/terraform/TerraformCrossAccountRole",
          "arn:aws:iam::${var.prod_account_id}:role/terraform/TerraformCrossAccountRole"
        ]
        Condition = {
          StringEquals = {
            "sts:ExternalId" = [
              "terraform-cross-account-${var.staging_account_id}",
              "terraform-cross-account-${var.dev_account_id}",
              "terraform-cross-account-${var.prod_account_id}"
            ]
          }
        }
      }
    ]
  })
}

# Cross-account role for PROD account - only in prod workspace
resource "aws_iam_role" "terraform_cross_account_role_prod" {
  count = local.create_prod_iam ? 1 : 0

  name = "TerraformCrossAccountRole"
  path = "/terraform/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.prod_service_account[0].arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "terraform-cross-account-${var.prod_account_id}"
          }
        }
      }
    ]
  })

  max_session_duration = 3600

  tags = {
    Purpose = "Terraform cross-account access"
    Environment = "prod"
    CreatedBy = "Terraform"
    ManagedBy = "prod-terraform-service-account"
  }
}

# Attach administrator access to prod role - only in prod workspace
resource "aws_iam_role_policy_attachment" "terraform_cross_account_role_prod" {
  count = local.create_prod_iam ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.terraform_cross_account_role_prod[0].name
}

# Output the access keys (handle securely!) - only when created
output "prod_service_account_access_key" {
  value = local.create_prod_iam ? aws_iam_access_key.prod_service_account[0].id : null
  description = "Access key for prod service account"
}

output "prod_service_account_secret_key" {
  value = local.create_prod_iam ? aws_iam_access_key.prod_service_account[0].secret : null
  sensitive = true
  description = "Secret key for prod service account"
}

output "prod_iam_resources_created" {
  value = local.create_prod_iam
  description = "Whether prod IAM resources were created in this workspace"
}