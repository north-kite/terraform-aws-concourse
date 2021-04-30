locals {
  name        = var.project_name
  environment = terraform.workspace == "default" ? "mgmt-dev" : terraform.workspace
  hosted_zone = join(".", [local.environment, var.root_domain])
  fqdn        = join(".", [local.name, local.hosted_zone])
  fqdn_int    = join(".", [local.name, "int", local.hosted_zone])

  zone_count = length(data.aws_availability_zones.current.zone_ids)
  zone_names = data.aws_availability_zones.current.names

  common_tags = {
    Environment = local.environment
    Application = local.name
    Terraform   = "true"
    Owner       = var.project_owner
    Team        = var.project_team
  }

  //  route_table_cidr_combinations = [
  //  # in pair, element zero is a route table ID and element one is a cidr block,
  //  # in all unique combinations.
  //  for pair in setproduct(module.vpc.private_route_table_ids, var.whitelist_cidr_blocks) : {
  //    rtb_id = pair[0]
  //    cidr   = pair[1]
  //  }
  //  ]
}
