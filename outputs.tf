output "vpc_id" {
  value = module.vpc.vpc_id
}

output "concourse_web_dns" {
  value = "https://${local.fqdn}"
}
