# ===============================================================================
# AWS Certificate Manager for Amazon API Gateway
# ===============================================================================
resource "aws_acm_certificate" "main_agw" {
  domain_name       = local.domain
  validation_method = "DNS"

  subject_alternative_names = [
    "*.${local.domain}",
  ]

  validation_option {
    domain_name       = local.domain
    validation_domain = local.domain
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-acm-certificate-agw"
  }
}

resource "aws_route53_record" "main_agw" {
  for_each = {
    for dvoagw in aws_acm_certificate.main_agw.domain_validation_options : dvoagw.domain_name => {
      name    = dvoagw.resource_record_name
      record  = dvoagw.resource_record_value
      type    = dvoagw.resource_record_type
      zone_id = aws_route53_zone.main.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = each.value.zone_id
  ttl             = 60

  records = [
    each.value.record,
  ]
}

resource "aws_acm_certificate_validation" "main_agw" {
  certificate_arn = aws_acm_certificate.main_agw.arn

  validation_record_fqdns = [
    for record in aws_route53_record.main_agw :
    record.fqdn
  ]
}


# ===============================================================================
# AWS Certificate Manager for Amazon CloudFront
# ===============================================================================
resource "aws_acm_certificate" "main_cloudfront" {
  domain_name       = local.domain
  validation_method = "DNS"
  provider          = aws.virginia

  subject_alternative_names = [
    "*.${local.domain}",
  ]

  validation_option {
    domain_name       = local.domain
    validation_domain = local.domain
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${local.project}-${local.env}-acm-certificate-cft"
  }
}

resource "aws_route53_record" "main_cloudfront" {
  for_each = {
    for dvocft in aws_acm_certificate.main_cloudfront.domain_validation_options : dvocft.domain_name => {
      name    = dvocft.resource_record_name
      record  = dvocft.resource_record_value
      type    = dvocft.resource_record_type
      zone_id = aws_route53_zone.main.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  type            = each.value.type
  zone_id         = each.value.zone_id
  ttl             = 60

  records = [
    each.value.record,
  ]
}

resource "aws_acm_certificate_validation" "main_cloudfront" {
  provider        = aws.virginia
  certificate_arn = aws_acm_certificate.main_cloudfront.arn

  validation_record_fqdns = [
    for record in aws_route53_record.main_cloudfront :
    record.fqdn
  ]
}
