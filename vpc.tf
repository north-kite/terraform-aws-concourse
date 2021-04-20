module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = join(".", [var.vpc_name, local.environment])
  cidr = var.cidr.vpc

  azs             = local.zone_names
  private_subnets = var.cidr.private
  public_subnets  = var.cidr.public

  enable_nat_gateway = true
  create_igw         = true
  enable_public_s3_endpoint = true
  enable_s3_endpoint = true
  enable_dynamodb_endpoint = true

  tags = {
    Terraform   = "true"
    Environment = local.environment
  }
}
