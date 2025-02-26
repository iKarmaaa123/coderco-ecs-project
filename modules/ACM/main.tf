resource "aws_acm_certificate" "my_aws_acm_certificate" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  options {
    certificate_transparency_logging_preference = "ENABLED"
  }

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "my_aws_route53_zone" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_route53_record" "cname_record" {
  for_each = {
    for dvo in aws_acm_certificate.my_aws_acm_certificate.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.my_aws_route53_zone.zone_id
}

resource "aws_acm_certificate_validation" "my_acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.my_aws_acm_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.cname_record : record.fqdn]
}