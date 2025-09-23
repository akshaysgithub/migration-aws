# Terraform Bootstrap & Setup

## Phase 1: Initial Setup Per Account

You need to initialize the backend separately for each workspace to store state files correctly in a shared S3 bucket.

---

### Step 1: PROD account (creates service account + prod role)

```bash
export AWS_ACCESS_KEY_ID=your-prod-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-prod-account-admin-secret

terraform workspace select prod || terraform workspace new prod
terraform init -backend-config="key=terraform/prod/terraform.tfstate"
terraform apply
```

# Step 2: STAGING account (creates staging role)
```bash
$env:AWS_ACCESS_KEY_ID = "your-prod-account-admin-key"
$env:AWS_SECRET_ACCESS_KEY = "your-prod-account-admin-secret"
For Linux
export AWS_ACCESS_KEY_ID=your-staging-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-staging-account-admin-secret

.\terraform workspace select staging || terraform workspace new staging
.\terraform init -backend-config="key=terraform/staging/terraform.tfstate"
.\terraform apply
```

# Step 3: DEV account (creates dev role)
```bash
export AWS_ACCESS_KEY_ID=your-dev-account-admin-key  
export AWS_SECRET_ACCESS_KEY=your-dev-account-admin-secret

terraform workspace select dev || terraform workspace new dev
terraform init -backend-config="key=terraform/dev/terraform.tfstate"
terraform apply
```


# Phase 2: Switch to using SA's

# Now use prod service account for everything
```bash
export AWS_ACCESS_KEY_ID=<prod-service-account-key>
export AWS_SECRET_ACCESS_KEY=<prod-service-account-secret>
```
# Set use_assume_role = true in terraform.tfvars

# Now these all work via cross-account role assumption:
```bash
terraform workspace select prod && terraform plan     # Prod SA → Prod role
terraform workspace select staging && terraform plan  # Prod SA → Staging role  
terraform workspace select dev && terraform plan      # Prod SA → Dev role
```