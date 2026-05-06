# After terraform creates our resources this will print out some key values
output "bucket_name" {
    value = aws_s3_bucket.url_shortener_bucket.bucket
}

output "cloudfront_url" {
    description = "URL of the deployed React app"
    value = "https://${aws_cloudfront_distribution.url_shortener.domain_name}"
}

# Distribution ID, this is needed to invalidate the CloudFront cached files
output "cloudfront_distribution_id" {
    description = "CloudFront distribution ID for cache invalidation"
    value = aws_cloudfront_distribution.url_shortener.id
}
