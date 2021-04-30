resource "aws_lb" "concourse_lb" {
  name               = "${local.environment}-concourse-web"
  internal           = false
  load_balancer_type = "application"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.concourse_lb.id]
  tags            = merge(local.common_tags, { Name = "${local.name}-lb" })

  //  TODO: Backfill logging bucket once such a thing is correctly defined, somewhere
  //  access_logs {
  //    bucket  = var.logging_bucket
  //    prefix  = "ELBLogs/${local.name}"
  //    enabled = true
  //  }
}

resource "aws_lb_listener" "concourse_https" {
  load_balancer_arn = aws_lb.concourse_lb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn = aws_acm_certificate.concourse_web_dl.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "FORBIDDEN"
      status_code  = "403"
    }
  }
}

resource "aws_lb_listener_rule" "concourse_https" {
  listener_arn = aws_lb_listener.concourse_https.arn

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.concourse_web_http.arn
  }

  condition {
    host_header {
      values = [
        local.fqdn,
      ]
    }
  }
}

resource "aws_lb_target_group" "concourse_web_http" {
  name     = "${local.environment}-concourse-web-http"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  health_check {
    port    = "8080"
    path    = "/"
    matcher = "200"
  }

  stickiness {
    enabled = false
    type    = "lb_cookie"
  }

  tags = merge(local.common_tags, { Name = local.name })
}

resource "aws_lb_target_group" "web_ssh" {
  name     = "${local.environment}-concourse-web-ssh"
  port     = 2222
  protocol = "TCP"
  vpc_id   = module.vpc.vpc_id

  # TODO healthcheck issues
  # port 2222 is known to log spam failed SSH connections into CloudWatch
  # port 8080 requires a security group rule to allow all traffic from the private subnets ip ranges, as we cannot
  # get the addresses of the NLB, from where the healthchecks originate, which is too broad to be accepted
  health_check {
    port     = "8080"
    protocol = "TCP"
  }

  # https://github.com/terraform-providers/terraform-provider-aws/issues/9093
  stickiness {
    enabled = false
    type    = "source_ip"
  }

  tags = merge(local.common_tags, { Name = local.name })
}

resource "aws_lb" "internal_lb" {
  name               = "${local.environment}-concourse-internal"
  internal           = true
  load_balancer_type = "network"
  subnets            = module.vpc.private_subnets
  tags            = merge(local.common_tags, { Name = "${local.name}-int-lb" })

  //  TODO: Backfill logging bucket once such a thing is correctly defined, somewhere
//  access_logs {
//    bucket  = var.logging_bucket
//    prefix  = "ELBLogs/${var.name}"
//    enabled = true
//  }
}

resource "aws_lb_listener" "ssh" {
  load_balancer_arn = aws_lb.internal_lb.arn
  port              = 2222
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_ssh.arn
  }
}
