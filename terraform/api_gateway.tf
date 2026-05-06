# Creates an HTTP API Gateway — receives requests from CloudFront
# and forwards them to your Lambda
resource "aws_apigatewayv2_api" "url_shortener" {
  name          = "url-shortener-api"
  protocol_type = "HTTP"
}

# The "integration" connects API Gateway to your Lambda function.
# When a request hits the API, this tells it "forward it to this Lambda"
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.url_shortener.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.url_shortener.invoke_arn
  payload_format_version = "2.0"
}

# POST /api/shorten — for creating a short URL
resource "aws_apigatewayv2_route" "post_shorten" {
  api_id    = aws_apigatewayv2_api.url_shortener.id
  route_key = "POST /api/shorten"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# GET /api/lengthen — for fetching the long URL
resource "aws_apigatewayv2_route" "get_long_url" {
  api_id    = aws_apigatewayv2_api.url_shortener.id
  route_key = "GET /api/lengthen"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# GET /api/{short_code} — for redirecting
resource "aws_apigatewayv2_route" "get_redirect" {
  api_id    = aws_apigatewayv2_api.url_shortener.id
  route_key = "GET /api/{short_code}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# "$default" stage — requests go straight to the base URL without
# needing a stage prefix (e.g. /prod/) in the path
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.url_shortener.id
  name        = "$default"
  auto_deploy = true
}

# Grants API Gateway permission to invoke your Lambda
resource "aws_lambda_permission" "api_gateway" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.url_shortener.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.url_shortener.execution_arn}/*/*"
}
