resource "aws_s3_bucket" "buckets" {
  for_each = toset(local.env.bucket_names)

  bucket = each.key
  acl    = "private"
}