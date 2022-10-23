
resource "aws_cloudwatch_log_group" "demo-api" {
  name = "/aws/lambda/lambda-apigateway-demo-api"

  retention_in_days = 30
}

resource "aws_apigatewayv2_api" "api_gateway_rest_api" {
  name          = "lambda-apigateway-demo-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "demo" {
  api_id = aws_apigatewayv2_api.api_gateway_rest_api.id

  name        = "demo"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.demo-api.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "api_gateway_rest_api" {
  api_id = aws_apigatewayv2_api.api_gateway_rest_api.id

  integration_uri    = aws_lambda_function.lambda.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "demo-api" {
  api_id = aws_apigatewayv2_api.api_gateway_rest_api.id

  route_key = "GET /api_token"
  target    = "integrations/${aws_apigatewayv2_integration.api_gateway_rest_api.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.api_gateway_rest_api.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway_rest_api.execution_arn}/*/*"
}

data "aws_route53_zone" "platform" {
  name = "platform.mystack.io"
}

resource "aws_route53_zone" "platform_sub_demo" {
  name = "demo.${data.aws_route53_zone.platform.name}"
  depends_on = [
    data.aws_route53_zone.platform
  ]
}

# Sub DNS for Demo

resource "aws_route53_record" "platform_sub-ns" {
  zone_id = data.aws_route53_zone.platform.zone_id
  name    = aws_route53_zone.platform_sub_demo.name
  type    = "NS"
  ttl     = "30"
  records = aws_route53_zone.platform_sub_demo.name_servers

}

resource "aws_route53_record" "demo" {
  for_each = {
    for dvo in aws_acm_certificate.certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.platform_sub_demo.zone_id
}

resource "aws_route53_record" "api_gateway" {
  name    = aws_apigatewayv2_domain_name.demo.domain_name
  type    = "A"
  zone_id = aws_route53_zone.platform_sub_demo.zone_id

  alias {
    name                   = aws_apigatewayv2_domain_name.demo.domain_name_configuration[0].target_domain_name
    zone_id                = aws_apigatewayv2_domain_name.demo.domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_acm_certificate" "certificate" {
  domain_name               = "api.demo.platform.mystack.io"
  subject_alternative_names = ["demo.platform.mystack.io", "*.demo.platform.builderhub.io"]
  validation_method         = "DNS"

  tags = {
    Environment = "demo-api"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "dns_validation" {
  certificate_arn         = aws_acm_certificate.certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.demo : record.fqdn]
}


resource "aws_apigatewayv2_domain_name" "demo" {
  domain_name = "api.demo.platform.mystack.io"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.certificate.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "demo" {
  api_id      = aws_apigatewayv2_api.api_gateway_rest_api.id
  domain_name = aws_apigatewayv2_domain_name.demo.id
  stage       = aws_apigatewayv2_stage.demo.id
}
