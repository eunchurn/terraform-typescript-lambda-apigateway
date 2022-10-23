output "api_base_url" {
  value       = aws_apigatewayv2_stage.demo.invoke_url
  description = "The public IP of the API"
}

output "api_domain" {
  value = aws_apigatewayv2_domain_name.demo.domain_name
}

output "function_name" {
  description = "Name of the Lambda function."

  value = aws_lambda_function.lambda.function_name
}
