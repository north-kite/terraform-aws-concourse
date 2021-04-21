variable "region" {
  default = ""
}

variable "project_name" {
  description = "The project / repo name for use in resource naming / tags"
  type        = string
  default     = "cicd"
}

variable "project_owner" {
  description = "The name of the project owner, for use in tagging"
  type        = string
  default     = "OPS"
}

variable "project_team" {
  description = "The name of the project team, for use in tagging"
  type        = string
  default     = "OPS"
}

variable "whitelist_cidr_blocks" {
  description = "Used as the whitelisted range for accessing the External Load Balancer for Concourse"
  type        = list(string)
  default = [
    "0.0.0.0/0"
  ]
}

variable "ami_id" {
  description = "AMI ID to use for launching Concourse Instances"
  type        = string
  default     = "ami-098828924dc89ea4a" // latest AL2 x86 AMI as of 15/02/21
}

variable "concourse_web_conf" {
  description = "Concourse Web config options"

  type = object({
    count                 = number
    max_instance_lifetime = number
    instance_type         = string
    environment_override  = map(string)
    rds_conf              = map(string)
    asg_scaling_config = object({
      night = object({
        min_size         = number
        max_size         = number
        desired_capacity = number
        time             = string
      })
      day = object({
        min_size         = number
        max_size         = number
        desired_capacity = number
        time             = string
      })
    })
  })

  default = {
    instance_type         = "t3.micro"
    max_instance_lifetime = 60 * 60 * 24 * 7
    count                 = 0
    environment_override  = {}
    rds_conf = {
      database_username = var.concourse_db_conf.username
      database_password = var.concourse_db_conf.password
      github_url        = var.github_url
    }
    asg_scaling_config = {
      night = {
        min_size         = 1
        max_size         = 1
        desired_capacity = 1
        time             = "0 19 * * 1-5"
      }
      day = {
        min_size         = 1
        max_size         = 3
        desired_capacity = 1
        time             = "0 7 * * 1-5"
      }
    }
  }
}

variable "concourse_worker_conf" {
  description = "Concourse Worker config options"
  type = object({
    instance_type        = string
    count                = number
    environment_override = map(string)
    asg_scaling_config = object({
      night = object({
        min_size         = number
        max_size         = number
        desired_capacity = number
        time             = string
      })
      day = object({
        min_size         = number
        max_size         = number
        desired_capacity = number
        time             = string
      })
    })
  })
  default = {
    instance_type        = "t3.micro"
    count                = 0
    environment_override = {}
    asg_scaling_config = {
      night = {
        min_size         = 1
        max_size         = 1
        desired_capacity = 1
        time             = "0 19 * * 1-5"
      }
      day = {
        min_size         = 1
        max_size         = 3
        desired_capacity = 1
        time             = "0 7 * * 1-5"
      }
    }
  }
}

variable "concourse_db_conf" {
  description = "database configuration options"

  type = object({
    instance_type           = string
    db_count                = number
    engine                  = string
    engine_version          = string
    backup_retention_period = number
    preferred_backup_window = string
    username                = string
    password                = string
  })

  default = {
    instance_type           = "db.t3.medium"
    db_count                = 1
    engine                  = "aurora-postgresql"
    engine_version          = "10.11"
    backup_retention_period = 14
    preferred_backup_window = "01:00-03:00"
    username                = "concourseadmin"
    password                = "4dm1n15strator" // TODO: Change this
  }
}

variable "cidr" {
  description = "The CIDR ranges used for the deployed subnets"

  type = object({
    vpc     = string
    private = list(string)
    public  = list(string)
  })

  default = {
    vpc     = "10.0.0.0/16"
    private = ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
    public  = ["10.0.100.0/24", "10.0.101.0/24", "10.0.102.0/24"]
  }
}

variable "vpc_name" {
  description = "The name to use for the VPC"
  type        = string
  default     = "cicd"
}

variable "root_domain" {
  description = "The root DNS domain on which to base the deployment"
  type        = string
  default     = "cicd.aws"
}

variable "auth_duration" {
  type        = string
  description = "Length of time for which tokens are valid. Afterwards, users will have to log back in"
  default     = "12h"
}

variable "github_url" {
  type        = string
  description = "The URL for the GitHub used for OAuth"
  default     = "github.com"
}