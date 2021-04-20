data "aws_route53_zone" "hosted_zone" {
  name         = local.hosted_zone
  private_zone = false
}

resource "aws_route53_record" "concourse_web_lb" {
  allow_overwrite = true
  name            = local.fqdn
  records         = [aws_lb.concourse_lb.dns_name]
  ttl             = 60
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.hosted_zone.zone_id
}