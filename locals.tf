locals {
  name        = var.project_name
  environment = terraform.workspace == "default" ? "mgmt-dev" : terraform.workspace
  hosted_zone = join(".", [local.environment, var.root_domain])
  fqdn        = join(".", [local.name, local.hosted_zone])
  zone_names  = data.aws_availability_zones.current.names

  common_tags = {
    Environment = local.environment
    Application = local.name
    Terraform   = "true"
    Owner       = var.project_owner
    Team        = var.project_team
  }
}
