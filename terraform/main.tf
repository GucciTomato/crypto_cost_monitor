terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0"
    }
    archive = { source = "hashicorp/archive" }
  }
}

variable "bucket" {
  type = string
}

locals {
  name = "crypto-cost-monitor"
}

provider "aws" {
  region = "eu-central-1"
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "raw" {
  bucket = var.bucket
}

data "archive_file" "lambda" {
  type = "zip"
  source_dir = "${path.module}/../build"  # build for ingestion script and non standard library: requests 
  output_path = "${path.module}/lambda.zip"
}

resource "aws_cloudwatch_log_group" "lambda" {
  name = "/aws/lambda/${local.name}-ingestion"
  retention_in_days = 14
}

resource "aws_iam_role" "lambda" {
  name = "${local.name}-ingestion"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.raw.arn}/*"
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "${aws_cloudwatch_log_group.lambda.arn}:*"
      }
    ]
  })
}

resource "aws_lambda_function_event_invoke_config" "ingestion" {
  function_name = aws_lambda_function.ingestion.function_name
  maximum_retry_attempts = 0 # standard retry behavior is dispensable because of 30 minute schedule
}

resource "aws_lambda_function" "ingestion" {
  function_name = "${local.name}-ingestion"
  role = aws_iam_role.lambda.arn
  runtime = "python3.13"
  handler = "ingestion.lambda_handler"
  filename = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  timeout = 30
  memory_size = 256

  environment {
    variables = { BUCKET = aws_s3_bucket.raw.bucket }
  }
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name = "${local.name}-schedule"
  schedule_expression = "rate(30 minutes)"
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule = aws_cloudwatch_event_rule.schedule.name
  arn  = aws_lambda_function.ingestion.arn
}

resource "aws_lambda_permission" "events" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.ingestion.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.schedule.arn
}