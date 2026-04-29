# Create an S3 bucket to store and serve the React app
resource "aws_s3_bucket" "url_shoCrtener_bucket" {
  bucket = var.bucket_name
}

# Configure the S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "url_shortener_bucket_ownership" {
  bucket = aws_s3_bucket.url_shortener_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Make the bucket public (NOT RECOMMENDED BEST PRACTICE FOR PRODUCTION)
resource "aws_s3_bucket_public_access_block" "url_shortener_bucket_public_access" {
  bucket = aws_s3_bucket.url_shortener_bucket.id

  block_public_acls       = false # acl = Access Control List - A way to control who can access your resources
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets   = false
}

# Configure the S3 bucket for static website hosting
resource "aws_s3_bucket_website_configuration" "url_shortener_website" {
  bucket = aws_s3_bucket.url_shortener_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# Make all files in the bucket publicly readable
resource "aws_s3_bucket_policy" "url_shortener_bucket_policy" {
    bucket = aws_s3_bucket.url_shortener_bucket.id

    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.url_shortener_bucket.arn}/*"
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.url_shortener_bucket_public_access] # Ensures the public access block is applied before this policy, stopping AWS returning a 403
}

