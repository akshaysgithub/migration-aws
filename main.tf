provider "aws" {
  alias  = "management"
  region = "us-east-1"
  profile = "management-account"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key

  # Assume role for dev or staging based on workspace
  assume_role {
    role_arn = locals.env.assume_role_arn
  }

}


#### serviceaccount.tf
resource "aws_iam_user" "service_account" {
  name = "service-account"
}

# Attach a policy to the service account allowing it to assume roles in dev, staging, and prod
resource "aws_iam_policy" "assume_roles_policy" {
  name        = "ServiceAccountAssumeRolesPolicy"
  description = "Allows service account to assume roles in dev, staging, and prod"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Resource = [
          "arn:aws:iam::<DEV_ACCOUNT_ID>:role/s3-role",
          "arn:aws:iam::<STAGING_ACCOUNT_ID>:role/s3-role",
          "arn:aws:iam::<PROD_ACCOUNT_ID>:role/admin-role"
        ]
      }
    ]
  })
}

# Attach the policy to the service account
resource "aws_iam_user_policy_attachment" "service_account_policy" {
  user       = aws_iam_user.service_account.name
  policy_arn = aws_iam_policy.assume_roles_policy.arn
}


resource "aws_iam_role" "admin_role" {
  provider = aws.prod
  name     = "admin-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::<MANAGEMENT_ACCOUNT_ID>:user/service-account"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach the AdministratorAccess policy to the role
resource "aws_iam_role_policy_attachment" "admin_policy_attachment" {
  provider  = aws.prod
  role      = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
