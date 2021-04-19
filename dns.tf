data "aws_route53_zone" "hosted_zone" {
  name         = local.hosted_zone
  private_zone = false
}
