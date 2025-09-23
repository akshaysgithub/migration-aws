
#### This code is for dev and staging account #####
# Create the role in dev and staging accounts
resource "aws_iam_role" "s3_role" {
  provider = aws.dev # Use staging provider for staging account
  name     = "s3-role"
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

# Attach a policy to allow S3 bucket creation
resource "aws_iam_policy" "s3_bucket_policy" {
  provider    = aws.dev # Use staging provider for staging account
  name        = "S3BucketCreationPolicy"
  description = "Allows S3 bucket creation"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:CreateBucket",
        Resource = "arn:aws:s3:::*"
      }
    ]
  })
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "s3_role_policy_attachment" {
  provider  = aws.dev # Use staging provider for staging account
  role      = aws_iam_role.s3_role.name
  policy_arn = aws_iam_policy.s3_bucket_policy.arn
}

