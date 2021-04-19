module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = var.vpc_name
  cidr = var.cidr.vpc

  azs             = local.zone_names
  private_subnets = var.cidr.private
  public_subnets  = var.cidr.public

  enable_nat_gateway = true
  create_igw         = true

  tags = {
    Terraform   = "true"
    Environment = local.environment
  }
}
