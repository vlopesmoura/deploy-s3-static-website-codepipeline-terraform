output "website_url" {
  description = "The URL of the static website hosted on S3"
  value       = "http://${aws_s3_bucket.my-s3-website-bucket.bucket}.s3-website-${var.region}.amazonaws.com"
}

output "codepipeline_name" {
  description = "The name of the CodePipeline created"
  value       = aws_codepipeline.website_pipeline.name
}