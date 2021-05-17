data "aws_route53_zone" "public" {
  name         = var.root_domain
  private_zone = false
}

resource "aws_route53_record" "concourse_web_lb" {
  allow_overwrite = true
  name            = local.fqdn
  records         = [aws_lb.concourse_lb.dns_name]
  ttl             = 60
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.public.zone_id
}

data "aws_route53_zone" "private" {
  count        = var.is_internal ? 1 : 0
  name         = var.root_domain
  private_zone = true
}

resource "aws_route53_record" "concourse_web_lb_private" {
  count           = var.is_internal ? 1 : 0
  allow_overwrite = true
  name            = local.fqdn
  records         = [aws_lb.concourse_lb.dns_name]
  ttl             = 60
  type            = "CNAME"
  zone_id         = data.aws_route53_zone.private[0].zone_id
}

resource "aws_route53_record" "concourse_int_lb" {
  name    = local.fqdn_int
  type    = "A"
  zone_id = data.aws_route53_zone.public.id

  alias {
    evaluate_target_health = false
    name                   = aws_lb.internal_lb.dns_name
    zone_id                = aws_lb.internal_lb.zone_id
  }
}
