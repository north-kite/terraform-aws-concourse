locals {
  name        = var.project_name
  environment = terraform.workspace == "default" ? "mgmt-dev" : replace(trimprefix(terraform.workspace, "kitchen-terraform-"), "-local", "")
  fqdn        = join(".", [local.name, var.root_domain])
  fqdn_int    = join(".", [local.name, "int", var.root_domain])
  account     = data.aws_caller_identity.current.account_id

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
  //  for pair in setproduct(local.vpc.private_route_table_ids, var.whitelist_cidr_blocks) : {
  //    rtb_id = pair[0]
  //    cidr   = pair[1]
  //  }
  //  ]
}
