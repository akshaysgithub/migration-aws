# outputs.tf

output "bucket_names" {
  description = "Names of created S3 buckets"
  value       = [for bucket in aws_s3_bucket.app_buckets : bucket.bucket]
}

output "bucket_arns" {
  description = "ARNs of created S3 buckets"
  value       = [for bucket in aws_s3_bucket.app_buckets : bucket.arn]
}

output "bucket_details" {
  description = "Detailed information about created buckets"
  value = {
    for name, bucket in aws_s3_bucket.app_buckets : name => {
      bucket_name = bucket.bucket
      bucket_arn  = bucket.arn
      region      = bucket.region
      versioning_enabled = contains(keys(aws_s3_bucket_versioning.app_buckets), name)
      encryption_enabled = contains(keys(aws_s3_bucket_server_side_encryption_configuration.app_buckets), name)
    }
  }
}

output "workspace" {
  description = "Current Terraform workspace"
  value       = terraform.workspace
}

output "target_account_id" {
  description = "Account ID being targeted"
  value       = local.account_ids[terraform.workspace]
}

output "assume_role_arn" {
  description = "ARN of the role being assumed"
  value       = local.assume_role_arn
}