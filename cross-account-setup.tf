# cross-account-roles.tf
# This file creates cross-account roles ONLY in staging and dev environments
# It's included in the main repository and uses workspace conditions

# Local values for cross-account setup (only for staging/dev)
locals {
  # Only create roles in staging and dev workspaces
  create_cross_account_role = contains(["staging", "dev"], terraform.workspace)

  prod_service_account_arn = "arn:aws:iam::${var.prod_account_id}:user/terraform/prod-terraform-service-account"
}

# Cross-account role for Terraform access (staging and dev only)
resource "aws_iam_role" "terraform_cross_account_role" {
  count = local.create_cross_account_role ? 1 : 0

  name = "TerraformCrossAccountRole"
  path = "/terraform/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = local.prod_service_account_arn
        }
        Condition = {
          StringEquals = {
            "sts:ExternalId" = "terraform-cross-account-${local.account_ids[terraform.workspace]}"
          }
        }
      }
    ]
  })

  # Optional: Add session duration (default is 1 hour, max is 12 hours)
  max_session_duration = 3600

  tags = {
    Purpose     = "Terraform cross-account access"
    Environment = terraform.workspace
    CreatedBy   = "Terraform"
    ManagedBy   = "prod-terraform-service-account"
    Workspace   = terraform.workspace
  }
}

# Attach AWS managed AdministratorAccess policy (staging and dev only)
resource "aws_iam_role_policy_attachment" "terraform_cross_account_admin" {
  count = local.create_cross_account_role ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.terraform_cross_account_role[0].name
}

# Output the role ARN (only when created)
output "cross_account_role_arn" {
  value = local.create_cross_account_role ? aws_iam_role.terraform_cross_account_role[0].arn : null
  description = "ARN of the cross-account role for Terraform access (staging/dev only)"
}

output "cross_account_role_created" {
  value = local.create_cross_account_role
  description = "Whether the cross-account role was created in this workspace"
}