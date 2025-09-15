output "api_endpoint" {
  value = aws_apigatewayv2_api.http.api_endpoint
}
output "s3_bucket_arn" {
  value = aws_s3_bucket.uploads.arn
}
