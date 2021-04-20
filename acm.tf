resource "aws_acm_certificate" "concourse_web_dl" {
  domain_name       = local.fqdn
  validation_method = "DNS"

  tags = local.common_tags
}

resource "aws_route53_record" "concourse_web_dl" {
  for_each = {
    for dvo in aws_acm_certificate.concourse_web_dl.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}

resource "aws_acm_certificate_validation" "concourse_web_dl" {
  certificate_arn         = aws_acm_certificate.concourse_web_dl.arn
  validation_record_fqdns = [for record in aws_route53_record.concourse_web_dl : record.fqdn]
}
