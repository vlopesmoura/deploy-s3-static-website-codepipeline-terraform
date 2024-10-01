provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "my-s3-website-bucket" {
  bucket = var.s3_bucket_name

  tags = {
    Name = var.s3_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.my-s3-website-bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket = aws_s3_bucket.my-s3-website-bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my-s3-website-bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.my-s3-website-bucket.arn}/*"
      }
    ]
  })
}

# Website Configuration
resource "aws_s3_bucket_website_configuration" "website_configuration" {
  bucket = aws_s3_bucket.my-s3-website-bucket.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

# IAM Role for CodePipeline
resource "aws_iam_role" "pipeline_role" {
  name = var.pipeline_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "codepipeline.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

# IAM Policy for CodePipeline Role
resource "aws_iam_role_policy" "pipeline_policy" {
  name = "CodePipelineRole_policy"
  role = aws_iam_role.pipeline_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "${aws_s3_bucket.my-s3-website-bucket.arn}",
          "${aws_s3_bucket.my-s3-website-bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "codecommit:GitPull",
          "codecommit:GetRepository",
          "codecommit:ListBranches",
          "codecommit:GetBranch",
          "codecommit:GetCommit",
          "codecommit:UploadArchive",
          "codecommit:GetUploadArchiveStatus"
        ]
        Resource = [
          "arn:aws:codecommit:${var.region}:${data.aws_caller_identity.current.account_id}:${var.codecommit_repo_name}"
        ]
      }
    ]
  })
}

# CodePipeline Setup
resource "aws_codepipeline" "website_pipeline" {
  name     = "website-deployment-pipeline"
  role_arn = aws_iam_role.pipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.my-s3-website-bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"

    action {
      name             = "SourceAction"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["SourceOutput"]

      configuration = {
        RepositoryName = "my-s3-static-website-01"
        BranchName     = "main"
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "DeployAction"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "S3"
      version         = "1"
      input_artifacts = ["SourceOutput"]

      configuration = {
        BucketName = aws_s3_bucket.my-s3-website-bucket.bucket
        Extract    = "true"
      }
    }
  }
}