# terraform.tfvars
# Replace with your actual account IDs

prod_account_id    = ""  # Your actual prod account ID
staging_account_id = ""  # Replace with actual staging account ID
dev_account_id     = ""  # Replace with actual dev account ID
region             = "us-east-1"

# Set to false for initial deployment to create IAM roles
# Set to true after roles are created to use assume role
use_assume_role = false