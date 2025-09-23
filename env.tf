locals {
  environment = terraform.workspace

  environments = {
    dev = {
      bucket_names = ["abcd", "bucket2"]
    },
    staging = {
      bucket_names = ["1234", "bucket3"]
    },
    prod = {
      bucket_names = ["prod-bucket1", "prod-bucket2"]
    }
  }
  
  assume_role_arns = {
    dev     = "arn:aws:iam::<DEV_ACCOUNT_ID>:role/s3-role"
    staging = "arn:aws:iam::<STAGING_ACCOUNT_ID>:role/s3-role"
   
   }

  bucket_names = local.environments[local.environment].bucket_names
  assume_role_arn = local.assume_role_arns[terraform.workspace]
}
