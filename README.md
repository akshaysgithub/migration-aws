# Step 1: PROD account (creates service account + prod role)
export AWS_ACCESS_KEY_ID=your-prod-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-prod-account-admin-secret
terraform workspace select prod
terraform apply

# Step 2: STAGING account (creates staging role)
export AWS_ACCESS_KEY_ID=your-staging-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-staging-account-admin-secret
terraform workspace select staging
terraform apply

# Step 3: DEV account (creates dev role)
export AWS_ACCESS_KEY_ID=your-dev-account-admin-key  
export AWS_SECRET_ACCESS_KEY=your-dev-account-admin-secret
terraform workspace select dev
terraform apply


# Phase 2: Switch to using SA's

# Now use prod service account for everything
export AWS_ACCESS_KEY_ID=<prod-service-account-key>
export AWS_SECRET_ACCESS_KEY=<prod-service-account-secret>

# Set use_assume_role = true in terraform.tfvars

# Now these all work via cross-account role assumption:
terraform workspace select prod && terraform plan     # Prod SA → Prod role
terraform workspace select staging && terraform plan  # Prod SA → Staging role  
terraform workspace select dev && terraform plan      # Prod SA → Dev role