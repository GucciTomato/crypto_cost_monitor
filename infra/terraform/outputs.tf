output "bucket_name" {
  value = aws_s3_bucket.raw.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.ingestion.function_name
}

output "snowflake_role_arn" {
  value = aws_iam_role.snowflake.arn
}