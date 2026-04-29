# After terraform creates our resources this will print out some key values
output "bucket_name" {
    value = "${aws_s3_bucket.url_shortener_bucket.bucket}"
}

output "bucket_domain_name" {
    description = "URL of the deployed React app"
    value = "http://${var.bucket_name}.s3-website.${var.region}.amazonaws.com"
}