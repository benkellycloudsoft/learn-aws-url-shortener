# Create an S3 bucket to store and serve the React app
resource "aws_s3_bucket" "url_shortener_bucket" {
  bucket        = var.bucket_name
  force_destroy = true # Allows terraform destroy to delete the bucket even when it contains objects
}

# Configure the S3 bucket ownership controls
resource "aws_s3_bucket_ownership_controls" "url_shortener_bucket_ownership" {
  bucket = aws_s3_bucket.url_shortener_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block all public access — CloudFront will access S3 privately via OAC,
# so the bucket no longer needs to be publicly accessible
resource "aws_s3_bucket_public_access_block" "url_shortener_bucket_public_access" {
  bucket = aws_s3_bucket.url_shortener_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Origin Access Control — this is CloudFront's identity. It lets CloudFront
# make authenticated requests to S3 without the bucket being public
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "url-shortener-s3-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront distribution — sits in front of both S3 (React app) and
# API Gateway (Lambda). Everything is served from one domain.
# Requests to /api/* go to API Gateway, everything else goes to S3
resource "aws_cloudfront_distribution" "url_shortener" {
  enabled             = true
  default_root_object = "index.html"

  # S3 origin — serves the React app's static files (HTML, JS, CSS)
  origin {
    domain_name              = aws_s3_bucket.url_shortener_bucket.bucket_regional_domain_name
    origin_id                = "s3"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # API Gateway origin — serves the Lambda backend
  origin {
    domain_name = trimsuffix(replace(aws_apigatewayv2_stage.default.invoke_url, "https://", ""), "/")
    origin_id   = "api"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Default behavior — all requests go to S3 (the React app)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # /api/* requests go to API Gateway instead of S3.
  # Caching is disabled because API responses are dynamic
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "api"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Access-Control-Request-Method", "Access-Control-Request-Headers"]
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Required block — no geo restrictions
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Use CloudFront's default SSL certificate
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Handle React client-side routing — if someone refreshes on a route
  # like /about, S3 would return 403. This serves index.html instead
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }
}

# Bucket policy — only allows CloudFront (via OAC) to read from S3.
# No one else can access the bucket directly
resource "aws_s3_bucket_policy" "url_shortener_bucket_policy" {
  bucket = aws_s3_bucket.url_shortener_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.url_shortener_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.url_shortener.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.url_shortener_bucket_public_access]
}

