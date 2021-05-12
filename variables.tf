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
  default     = "ami-098828924dc89ea4a" // latest AL2 x86 AMI as of 15/02/21 #TODO this is out of date
}

variable "concourse_web_conf" {
  description = "Concourse Web config options"

  type = object({
    count                 = number
    max_instance_lifetime = number
    instance_type         = string
    environment_override  = map(string)
    key_name              = string
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
    instance_type         = "t2.2xlarge"
    max_instance_lifetime = 60 * 60 * 24 * 7
    count                 = 1
    environment_override  = {}
    key_name              = null
    asg_scaling_config = {
      night = {
        min_size         = 1
        max_size         = 3
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
    instance_type         = string
    count                 = number
    environment_override  = map(string)
    garden_network_pool   = string
    garden_max_containers = string
    log_level             = string
    key_name              = string
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
    instance_type         = "t2.2xlarge"
    count                 = 3
    environment_override  = {}
    garden_network_pool   = "172.16.0.0/21"
    garden_max_containers = "350"
    log_level             = "error"
    key_name              = null
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
  description = "(Optional) database configuration options for database creation"

  type = object({
    instance_type           = string
    db_count                = number
    engine                  = string
    engine_version          = string
    backup_retention_period = number
    preferred_backup_window = string
    skip_final_snapshot     = bool
  })

  default = {
    instance_type           = "db.t3.medium"
    db_count                = 1
    engine                  = "aurora-postgresql"
    engine_version          = "10.11"
    backup_retention_period = 14
    preferred_backup_window = "01:00-03:00"
    skip_final_snapshot     = false
  }
}

variable "create_database" {
  description = "(Optional) Flag to indicate if new database needs to be created."
  type        = bool
  default     = true
}

variable "existing_database_config" {
  description = "(Optional) Configuration of existing database for Concourse to use"
  type = object({
    endpoint          = string
    db_name           = string
    user              = string
    password          = string
    security_group_id = string
  })
  default = {
    endpoint          = null
    db_name           = null
    user              = null
    password          = null
    security_group_id = null
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

variable "create_vpc" {
  description = "(Optional) Flag to indicate if new VPC needs to be created."
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "(Optional) The id of the VPC to create resources in. Requires `create_vpc` to be `false`."
  type        = string
  default     = null
}

variable "public_subnets" {
  description = "(Optional) List of public subnet IDs and CIDRs."
  type = object({
    ids         = list(string)
    cidr_blocks = list(string)
  })
  default = {
    ids         = []
    cidr_blocks = []
  }
}

variable "private_subnets" {
  description = "(Optional) List of private subnet IDs and CIDRs."
  type = object({
    ids         = list(string)
    cidr_blocks = list(string)
  })
  default = {
    ids         = []
    cidr_blocks = []
  }
}

variable "vpc_endpoint_s3_pl_id" {
  description = "(Optional) The prefix list for the S3 VPC endpoint."
  type        = string
  default     = ""
}

variable "vpc_endpoint_dynamodb_pl_id" {
  description = "(Optional) The prefix list for the DynamoDB VPC endpoint."
  type        = string
  default     = ""
}

variable "root_domain" {
  description = "The root DNS domain on which to base the deployment"
  type        = string
  default     = "cicd.aws"
}

variable "github_url" {
  type        = string
  description = "The URL for the GitHub used for OAuth"
  default     = "github.com"
}

variable "concourse_version" {
  type        = string
  description = "The Concourse version to deploy"
  default     = "7.2.0"
}


variable "concourse_sec" {
  description = "Concourse Security Config"

  type = object({
    concourse_username                     = string
    concourse_password                     = string
    concourse_auth_duration                = string
    concourse_db_username                  = string
    concourse_db_password                  = string
    session_signing_key_public_secret_arn  = string
    session_signing_key_private_secret_arn = string
    tsa_host_key_private_secret_arn        = string
    tsa_host_key_public_secret_arn         = string
    worker_key_private_secret_arn          = string
    worker_key_public_secret_arn           = string
  })

  default = {
    concourse_username                     = "concourseadmin"
    concourse_password                     = "concoursePassword123!"
    concourse_auth_duration                = "12h"
    concourse_db_username                  = "concourseadmin"
    concourse_db_password                  = "4dm1n15strator"
    session_signing_key_public_secret_arn  = "ARN_NOT_SET"
    session_signing_key_private_secret_arn = "ARN_NOT_SET"
    tsa_host_key_private_secret_arn        = "ARN_NOT_SET"
    tsa_host_key_public_secret_arn         = "ARN_NOT_SET"
    worker_key_private_secret_arn          = "ARN_NOT_SET"
    worker_key_public_secret_arn           = "ARN_NOT_SET"
  }
}

variable "concourse_saml_conf" {
  description = "Concourse SAML config for e.g. Okta"

  type = object({
    display_name = string
    url          = string
    ca_cert      = string
    issuer       = string
  })

  default = {
    display_name = ""
    url          = ""
    ca_cert      = ""
    issuer       = ""
  }
}

variable "concourse_teams_conf" {
  description = "Concourse teams config"
  type        = map(any)
  default     = {}
}

variable "concourse_internal_allowed_principals" {
  description = "A list of AWS principals that are allowed to reach Concourse via its internal load balancer"
  type        = list(string)
  default     = []
}

variable "proxy" {
  description = "(Optional) Configure HTTP, HTTPS, and NO_PROXY"
  type = object({
    http_proxy  = string
    https_proxy = string
    no_proxy    = string
  })
  default = {
    http_proxy  = null
    https_proxy = null
    no_proxy    = null
  }
}

variable "tags" {
  description = "(Optional) Tags to apply to aws resources"
  type        = map(string)
  default     = {}
}
