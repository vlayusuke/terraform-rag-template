# ===============================================================================
# Amazon API Gateway (REST API / Response API)
# ===============================================================================
resource "aws_api_gateway_rest_api" "response_api" {
  name        = "${local.project}-${local.env}-agw-response-api"
  description = "Amazon API Gateway for ${local.project}-${local.env} invoking AWS Lambda functions"

  tags = {
    Name = "${local.project}-${local.env}-agw-response-api"
  }
}

resource "aws_api_gateway_domain_name" "response_api" {
  domain_name              = "*.${local.domain}"
  regional_certificate_arn = aws_acm_certificate.main_agw.arn
  security_policy          = "TLS_1_2"

  endpoint_configuration {
    types = [
      "REGIONAL",
    ]
  }

  tags = {
    Name = "${local.project}-${local.env}-agw-domain-name"
  }
}

resource "aws_api_gateway_base_path_mapping" "response_api" {
  api_id      = aws_api_gateway_rest_api.response_api.id
  stage_name  = aws_api_gateway_stage.response_api_stage.stage_name
  domain_name = aws_api_gateway_domain_name.response_api.domain_name
}

resource "aws_api_gateway_resource" "response_api_resource" {
  rest_api_id = aws_api_gateway_rest_api.response_api.id
  parent_id   = aws_api_gateway_rest_api.response_api.root_resource_id
  path_part   = "response"
}

resource "aws_api_gateway_method" "response_api_method" {
  rest_api_id      = aws_api_gateway_rest_api.response_api.id
  resource_id      = aws_api_gateway_resource.response_api_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.querystring.key" = true
  }
}

resource "aws_api_gateway_method_response" "response_api_method_post_200" {
  rest_api_id = aws_api_gateway_rest_api.response_api.id
  resource_id = aws_api_gateway_resource.response_api_resource.id
  http_method = aws_api_gateway_method.response_api_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "response_api_method_post_400" {
  rest_api_id = aws_api_gateway_rest_api.response_api.id
  resource_id = aws_api_gateway_resource.response_api_resource.id
  http_method = aws_api_gateway_method.response_api_method.http_method
  status_code = "400"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_method_response" "response_api_method_post_500" {
  rest_api_id = aws_api_gateway_rest_api.response_api.id
  resource_id = aws_api_gateway_resource.response_api_resource.id
  http_method = aws_api_gateway_method.response_api_method.http_method
  status_code = "500"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

# Add Request Validator
resource "aws_api_gateway_request_validator" "validator" {
  name                        = "varidator"
  rest_api_id                 = aws_api_gateway_rest_api.response_api.id
  validate_request_parameters = true
}

resource "aws_api_gateway_integration" "response_api_integration" {
  rest_api_id             = aws_api_gateway_rest_api.response_api.id
  resource_id             = aws_api_gateway_resource.response_api_resource.id
  http_method             = aws_api_gateway_method.response_api_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.response_api.invoke_arn
}

resource "aws_api_gateway_integration_response" "integration_response_post_200" {
  rest_api_id       = aws_api_gateway_rest_api.response_api.id
  resource_id       = aws_api_gateway_resource.response_api_resource.id
  http_method       = aws_api_gateway_method.response_api_method.http_method
  status_code       = aws_api_gateway_method_response.response_api_method_post_200.status_code
  selection_pattern = "200"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "integration_response_post_400" {
  rest_api_id       = aws_api_gateway_rest_api.response_api.id
  resource_id       = aws_api_gateway_resource.response_api_resource.id
  http_method       = aws_api_gateway_method.response_api_method.http_method
  status_code       = aws_api_gateway_method_response.response_api_method_post_400.status_code
  selection_pattern = "4\\d{2}"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_integration_response" "integration_response_post_500" {
  rest_api_id       = aws_api_gateway_rest_api.response_api.id
  resource_id       = aws_api_gateway_resource.response_api_resource.id
  http_method       = aws_api_gateway_method.response_api_method.http_method
  status_code       = aws_api_gateway_method_response.response_api_method_post_500.status_code
  selection_pattern = "5\\d{2}"

  response_templates = {
    "application/json" = ""
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }
}

resource "aws_api_gateway_deployment" "response_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.response_api.id

  depends_on = [
    aws_api_gateway_integration.response_api_integration,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "response_api_stage" {
  stage_name    = local.env
  rest_api_id   = aws_api_gateway_rest_api.response_api.id
  deployment_id = aws_api_gateway_deployment.response_api_deployment.id

  tags = {
    Name = "${local.project}-${local.env}-agw-stage"
  }
}

resource "aws_lambda_permission" "apigateway_response_api" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.response_api.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.response_api.execution_arn}/*/*"
}
