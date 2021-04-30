resource "aws_security_group" "concourse_lb" {
  vpc_id = module.vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "concourse_web" {
  name        = "ConcourseWeb"
  description = "Concourse Web Nodes"
  vpc_id      = module.vpc.vpc_id
  tags        = merge(local.common_tags, { Name = local.name })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "concourse_worker" {
  name        = "ConcourseWorker"
  description = "ConcourseWorker"
  vpc_id      = module.vpc.vpc_id
  tags        = merge(local.common_tags, { Name = "${local.name}-lb" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "concourse_db" {
  vpc_id = module.vpc.vpc_id
  tags   = merge(local.common_tags, { Name = "${local.name}-db" })
}

resource "aws_security_group" "concourse_vpc_endpoints" {
  name        = "ConcourseVPCEndpoints"
  description = "Concourse VPC Endpoints"
  vpc_id      = module.vpc.vpc_id
  tags        = merge(local.common_tags, { Name = local.name })

  lifecycle {
    create_before_destroy = true
  }
}

//resource "aws_security_group_rule" "internal_ssh_from_bastion_egress" {
//  from_port                = 22
//  protocol                 = "tcp"
//  source_security_group_id = aws_security_group.concourse_vpc_endpoints.id
//  to_port                  = 22
//  type                     = "ingress"
//  security_group_id        = aws_security_group.concourse_web.id
//}

resource "aws_security_group_rule" "lb_external_https_in" {
  description       = "enable inbound connectivity from whitelisted endpoints"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.concourse_lb.id
  cidr_blocks       = var.whitelist_cidr_blocks
}

resource "aws_security_group_rule" "web_lb_in_http" {
  description              = "inbound traffic to web nodes from lb"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  security_group_id        = aws_security_group.concourse_web.id
  source_security_group_id = aws_security_group.concourse_lb.id
}

resource "aws_security_group_rule" "lb_web_out_http" {
  description              = "outbound traffic from web nodes to lb"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 8080
  to_port                  = 8080
  security_group_id        = aws_security_group.concourse_lb.id
  source_security_group_id = aws_security_group.concourse_web.id
}

resource "aws_security_group_rule" "int_lb_web_in_http" {
  description       = "inbound traffic to web nodes from internal lb"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 8080
  to_port           = 8080
  security_group_id = aws_security_group.concourse_web.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
}

resource "aws_security_group_rule" "web_internal_in_tcp" {
  description              = "allow web nodes to communicate with each other"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  security_group_id        = aws_security_group.concourse_web.id
  source_security_group_id = aws_security_group.concourse_web.id
}

resource "aws_security_group_rule" "web_internal_out_tcp" {
  description              = "web_internal_out_tcp"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 0
  to_port                  = 65535
  security_group_id        = aws_security_group.concourse_web.id
  source_security_group_id = aws_security_group.concourse_web.id
}

resource "aws_security_group_rule" "web_internal_out_all" {
  description       = "web_internal_out_all"
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  security_group_id = aws_security_group.concourse_web.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "worker_internal_out_all" {
  description       = "web_internal_out_all"
  type              = "egress"
  protocol          = "all"
  from_port         = 0
  to_port           = 65535
  security_group_id = aws_security_group.concourse_worker.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "web_lb_in_ssh" {
  description       = "inbound traffic to web nodes from worker nodes via lb"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 2222
  to_port           = 2222
  security_group_id = aws_security_group.concourse_web.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
}

resource "aws_security_group_rule" "web_db_out" {
  description              = "outbound connectivity from web nodes to db"
  type                     = "egress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.concourse_web.id
  source_security_group_id = aws_security_group.concourse_db.id
}

resource "aws_security_group_rule" "db_web_in" {
  description              = "inbound connectivity to db from web nodes"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = 5432
  to_port                  = 5432
  security_group_id        = aws_security_group.concourse_db.id
  source_security_group_id = aws_security_group.concourse_web.id
}

resource "aws_security_group_rule" "web_outbound_s3_https" {
  description       = "s3 outbound https connectivity"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.concourse_web.id
  prefix_list_ids   = [module.vpc.vpc_endpoint_s3_pl_id]
}

resource "aws_security_group_rule" "web_outbound_s3_http" {
  description       = "s3 outbound http connectivity (for YUM updates)"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.concourse_web.id
  prefix_list_ids   = [module.vpc.vpc_endpoint_s3_pl_id]
}

//resource "aws_security_group_rule" "web_lb_in_metrics" {
//  description       = "inbound traffic to web nodes metrics port"
//  from_port         = 9090
//  protocol          = "tcp"
//  security_group_id = aws_security_group.concourse_web.id
//  to_port           = 9090
//  type              = "ingress"
//  // TODO: Implement some kinda metrics infra and point this towards it
//  cidr_blocks = var.vpc.aws_subnets_private.*.cidr_block
//}

resource "aws_security_group_rule" "worker_lb_out_ssh" {
  description       = "outbound traffic to web nodes from worker nodes via lb"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 2222
  to_port           = 2222
  security_group_id = aws_security_group.concourse_worker.id
  cidr_blocks       = module.vpc.private_subnets_cidr_blocks
}

resource "aws_security_group_rule" "worker_outbound_s3_https" {
  description       = "s3 outbound https connectivity"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.concourse_worker.id
  prefix_list_ids   = [module.vpc.vpc_endpoint_s3_pl_id]
}

resource "aws_security_group_rule" "worker_outbound_s3_http" {
  description       = "s3 outbound http connectivity (for YUM updates)"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.concourse_worker.id
  prefix_list_ids   = [module.vpc.vpc_endpoint_s3_pl_id]
}

resource "aws_security_group_rule" "web_outbound_dynamodb_https" {
  description       = "dynamodb outbound https connectivity"
  type              = "egress"
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.concourse_worker.id
  prefix_list_ids   = [module.vpc.vpc_endpoint_dynamodb_pl_id]
}

//resource "aws_security_group_rule" "worker_ec2_packer_ssh" {
//  description       = "Allow EC2 instances to receive SSH traffic"
//  type              = "ingress"
//  protocol          = "tcp"
//  from_port         = 22
//  to_port           = 22
//  self              = true
//  security_group_id = aws_security_group.concourse_worker.id
//}
