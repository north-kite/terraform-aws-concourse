module "database" {
  count                   = var.create_database ? 1 : 0
  source                  = "./modules/database"
  name                    = local.name
  environment             = local.environment
  allowed_security_groups = [aws_security_group.concourse_web.id]
  encrypt_storage         = true
  database                = var.concourse_db_conf
  database_credentials = {
    username = var.concourse_sec.concourse_db_username
    password = var.concourse_sec.concourse_db_password
  }
  vpc = {
    id      = local.vpc.vpc_id
    subnets = local.vpc.private_subnets
  }
  tags = var.tags
}

locals {
  database = var.create_database ? {
    endpoint          = module.database[0].outputs.endpoint
    database_name     = module.database[0].outputs.database_name
    security_group_id = module.database[0].outputs.security_group_id
    } : {
    endpoint          = var.existing_database_config.endpoint
    database_name     = var.existing_database_config.db_name
    security_group_id = var.existing_database_config.security_group_id
  }
}
