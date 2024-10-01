variable "region" {
  description = "The AWS region to deploy resources"
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "The name of the S3 bucket for static website hosting"
  default     = "my-s3-static-website-01-s3-bucket"
}

variable "codecommit_repo_name" {
  description = "The name of the AWS CodeCommit repository"
  default     = "my-s3-static-website-01"
}

variable "pipeline_role_name" {
  description = "The name of the IAM role for CodePipeline"
  default     = "CodePipelineRole"
}

variable "index_document" {
  description = "The index document for the S3 bucket website configuration"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error document for the S3 bucket website configuration"
  type        = string
  default     = "error.html"
}