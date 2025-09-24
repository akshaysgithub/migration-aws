# Terraform Bootstrap & Setup

## Phase 1: Initial Setup Per Account

You need to initialize the backend separately for each workspace to store state files correctly in a shared S3 bucket.

---

### Step 1: PROD account (creates service account + prod role)

```bash
export AWS_ACCESS_KEY_ID=your-prod-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-prod-account-admin-secret
.\terraform init
.\terraform workspace select prod 
.\terrform plan
.\terraform apply
```

# Step 2: STAGING account (creates staging role)
```bash
$env:AWS_ACCESS_KEY_ID = "your-prod-account-admin-key"
$env:AWS_SECRET_ACCESS_KEY = "your-prod-account-admin-secret"
For Linux
export AWS_ACCESS_KEY_ID=your-staging-account-admin-key
export AWS_SECRET_ACCESS_KEY=your-staging-account-admin-secret

.\terraform init
.\terraform workspace select prod 
.\terrform plan
.\terraform apply
```

# Step 3: DEV account (creates dev role)
```bash
export AWS_ACCESS_KEY_ID=your-dev-account-admin-key  
export AWS_SECRET_ACCESS_KEY=your-dev-account-admin-secret

.\terraform init
.\terraform workspace select prod 
.\terrform plan
.\terraform apply
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

# To clear changes

```bash
# Clear environment variables
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
unset AWS_PROFILE

# Clear any cached credentials
rm -rf ~/.aws/cli/cache/
```

# Install fleeting plugin

```bash
gitlab-runner fleeting install

For istolating based on environments, we need to run this

sudo gitlab-runner register \
  --non-interactive \
  --url "https://gitlab.com/" \
  --registration-token "XYZ123" \
  --executor "docker" \
  --description "dev-runner" \
  --tag-list "dev" \
  --run-untagged="false" \
  --locked="true"

```