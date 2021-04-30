provider "aws" {
  region = var.region
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["*amzn2-ami-hvm*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Used for supporting infra
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

module "concourse" {
  source = "../../"

  region        = var.region
  project_owner = "testing"
  project_team  = "kitchen"
  ami_id        = data.aws_ami.amazon_linux_2.id

  cidr = {
    vpc     = "10.1.0.0/16"
    private = ["10.1.0.0/24", "10.1.1.0/24", "10.1.2.0/24"]
    public  = ["10.1.100.0/24", "10.1.101.0/24", "10.1.102.0/24"]
  }

  concourse_sec = {
    concourse_username                     = "test"
    concourse_password                     = "test"
    concourse_auth_duration                = "24h"
    concourse_db_username                  = "test-db"
    concourse_db_password                  = "test-db-password"
    session_signing_key_public_secret_arn  = aws_secretsmanager_secret_version.session_signing_key_public.arn
    session_signing_key_private_secret_arn = aws_secretsmanager_secret_version.session_signing_key_private.arn
    tsa_host_key_private_secret_arn        = aws_secretsmanager_secret_version.tsa_host_key_private.arn
    tsa_host_key_public_secret_arn         = aws_secretsmanager_secret_version.tsa_host_key_public.arn
    worker_key_private_secret_arn          = aws_secretsmanager_secret_version.worker_key_private.arn
    worker_key_public_secret_arn           = aws_secretsmanager_secret_version.worker_key_public.arn
  }

  root_domain = var.root_domain
}
