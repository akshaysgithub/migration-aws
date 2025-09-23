
# S3 buckets based on workspace and bucket names array
resource "aws_s3_bucket" "app_buckets" {
  for_each = toset(local.current_buckets)
  bucket   = each.value

  tags = {
    Name        = each.value
    Environment = terraform.workspace
  }
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "app_buckets" {
  for_each = local.current_config.versioning ? toset(local.current_buckets) : toset([])
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "app_buckets" {
  for_each = local.current_config.encryption ? toset(local.current_buckets) : toset([])
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "app_buckets" {
  for_each = toset(local.current_buckets)
  bucket   = aws_s3_bucket.app_buckets[each.key].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}