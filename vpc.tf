module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.78.0"

  name = join(".", [var.vpc_name, local.environment])
  cidr = var.cidr.vpc

  azs             = local.zone_names
  private_subnets = var.cidr.private
  public_subnets  = var.cidr.public

  enable_nat_gateway        = true
  create_igw                = true

  enable_public_s3_endpoint = true
  enable_s3_endpoint        = true
  enable_dynamodb_endpoint  = true
  enable_ssm_endpoint       = true
  enable_ssmmessages_endpoint = true
  enable_ec2messages_endpoint = true

  ssm_endpoint_security_group_ids = [aws_security_group.concourse_vpc_endpoints.id]
  ssmmessages_endpoint_security_group_ids = [aws_security_group.concourse_vpc_endpoints.id]
  ec2messages_endpoint_security_group_ids = [aws_security_group.concourse_vpc_endpoints.id]

  tags = {
    Terraform   = "true"
    Environment = local.environment
  }
}
