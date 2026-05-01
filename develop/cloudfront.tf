# ===============================================================================
# Amazon CloudFront Distribution
# ===============================================================================
resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = false
  http_version    = "http2and3"
  comment         = "${local.project}-${local.env} CloudFront Distribution"
  web_acl_id      = aws_wafv2_web_acl.main.arn

  aliases = [
    "${local.env}.${local.domain}",
  ]

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.main_cloudfront.arn
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }

  origin {
    domain_name = aws_api_gateway_domain_name.response_api.regional_domain_name
    origin_id   = aws_api_gateway_rest_api.response_api.name

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 60
      origin_ssl_protocols = [
        "TLSv1.2",
      ]
    }
  }

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS",
    ]
    cached_methods = [
      "GET",
      "HEAD",
    ]

    compress               = false
    default_ttl            = 0
    max_ttl                = 0
    min_ttl                = 0
    smooth_streaming       = false
    target_origin_id       = aws_api_gateway_rest_api.response_api.name
    trusted_signers        = []
    viewer_protocol_policy = "allow-all"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }

      headers = [
        "Access-Control-Request-Headers",
        "Access-Control-Request-Method",
        "Origin",
      ]
    }

    #     function_association {
    #       event_type   = "viewer-request"
    #       function_arn = aws_cloudfront_function.basic_auth.arn
    #     }
  }

  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["JP"]
    }
  }

  depends_on = [
    aws_acm_certificate_validation.main,
  ]

  tags = {
    Name = "${local.project}-${local.env}-cloudfront-distribution"
  }
}


# If you want to use CloudFront Functions, you can add the resource definition here. However, please note that CloudFront Functions are only supported in certain regions and may not be available in all AWS accounts. Make sure to check the AWS documentation for the latest information on CloudFront Functions availability and usage.
# ===============================================================================
# CloudFront Functions
# ===============================================================================
# resource "aws_cloudfront_function" "basic_auth" {
#   name    = "${local.project}-${local.env}-cf-fnc-basic-auth"
#   runtime = "cloudfront-js-2.0"
#   comment = "${local.project}-${local.env} CloudFront Functions for basic authentication"
#   publish = true
#   code    = file("${path.module}/files/cloudfront_functions/basic_auth.js")
# }
