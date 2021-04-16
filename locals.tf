locals {
  name        = var.project_name
  environment = terraform.workspace == "default" ? "dev" : terraform.workspace
  fqdn        = join(".", [local.name, local.environment, var.root_domain]) //TODO: Setup some DNS...
  zone_names  = data.aws_availability_zones.current.names

  common_tags = {
    Name        = local.name
    Environment = local.environment
    Application = local.name
    Terraform   = "true"
    Owner       = var.project_owner
    Team        = var.project_team
  }
}
