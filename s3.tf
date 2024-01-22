provider "aws" {
  region = "us-east-1" # Set your preferred default region
}

# Create KMS key in the primary region
resource "aws_kms_key" "primary_kms_key" {
  description             = "Primary KMS Key"
  deletion_window_in_days = 30
}

# Create S3 bucket in the primary region
resource "aws_s3_bucket" "primary_bucket" {
  bucket = "primary-bucket"
  acl    = "private"
  region = "us-east-1" # Primary region

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.primary_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}

# Create S3 bucket in the secondary region
resource "aws_s3_bucket" "secondary_bucket" {
  bucket = "secondary-bucket"
  acl    = "private"
  region = "us-west-2" # Secondary region

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.primary_kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }
}

# Enable replication from primary to secondary bucket
resource "aws_s3_bucket_replication" "primary_to_secondary_replication" {
  source_bucket      = aws_s3_bucket.primary_bucket.bucket
  destination_bucket = aws_s3_bucket.secondary_bucket.bucket
}

# Enable replication from secondary to primary bucket
resource "aws_s3_bucket_replication" "secondary_to_primary_replication" {
  source_bucket      = aws_s3_bucket.secondary_bucket.bucket
  destination_bucket = aws_s3_bucket.primary_bucket.bucket
}
