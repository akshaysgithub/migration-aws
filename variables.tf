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

variable "bucket_names" {
  description = "Map of environment to list of bucket names"
  type = map(list(string))
  default = {
    prod = [
      "prod-bucket-names",
    ]
    staging = [
      "staging-bucket-names",
    ]
    dev = [
      "dev-bucket-name"
    ]
  }
}