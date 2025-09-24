# variables.tf

# variables.tf

variable "prod_account_id" {
  description = "AWS Account ID for Production"
  type        = string
}

variable "staging_account_id" {
  description = "AWS Account ID for Staging"
  type        = string
}

variable "dev_account_id" {
  description = "AWS Account ID for Development"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "use_assume_role" {
  description = "Whether to use assume role for cross-account access. Set to false for initial deployment."
  type        = bool
  default     = false
}

variable "terraform_state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform state backend"
  type        = string
  default     = "rdof-terraform-state-prod"
}

variable "terraform_state_lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "enable_cross_account_s3_access" {
  description = "Whether to enable cross-account S3 access from staging and dev to prod buckets"
  type        = bool
  default     = true
}


variable "bucket_names" {
  description = "Map of environment to list of bucket names"
  type = map(list(string))
  default = {
    prod = [
      "prod-bucket-names-abcdddd",
    ]
    staging = [
      "staging-bucket-names-abcdddd",
    ]
    dev = [
      "dev-bucket-name-abcdddd"
    ]
  }
}