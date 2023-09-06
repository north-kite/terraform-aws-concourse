data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "current" {}

terraform {
  required_version = ">= 0.14.0"

  required_providers {
    random = "~> 2.0"
    aws    = "~> 4.67"
  }
}
