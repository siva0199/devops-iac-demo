resource "aws_s3_bucket" "uploads" {
  bucket = "demo-upload-bucket"
}

resource "aws_s3_bucket_public_access_block" "uploads" {
  bucket = aws_s3_bucket.uploads.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/../../lambda_code/lambda_function.py"
  output_path = "lambda_function.zip"
}

resource "aws_lambda_function" "upload" {
  filename      = "lambda_function.zip"
  function_name = "upload_lambda"
  role          = var.lambda_execution_role_arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"
  source_code_hash = data.archive_file.lambda.output_base64sha256
}

resource "aws_apigatewayv2_api" "http" {
  name          = "demo-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.http.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.upload.invoke_arn
}

resource "aws_apigatewayv2_route" "post" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "POST /upload"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}
