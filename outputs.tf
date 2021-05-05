output "vpc_id" {
  value = local.vpc.vpc_id
}

output "concourse_web_dns" {
  value = "https://${local.fqdn}"
}

output "web_url" {
  value = aws_route53_record.concourse_web_lb.fqdn

}
