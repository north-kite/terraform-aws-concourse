resource "aws_launch_template" "concourse_web" {
  name_prefix                          = "${local.name}-concourse-web"
  image_id                             = var.ami_id
  instance_type                        = var.concourse_web_conf.instance_type
  instance_initiated_shutdown_behavior = "terminate"
  key_name                             = var.concourse_web_conf.key_name


  user_data = data.template_cloudinit_config.web_bootstrap.rendered

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_type           = var.concourse_web_conf.ebs_volume.type
      iops                  = var.concourse_web_conf.ebs_volume.iops
      volume_size           = var.concourse_web_conf.ebs_volume.size
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    no_device   = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.concourse_web.arn
  }

  tags = merge(
    local.common_tags,
    { Name = "${local.environment}-concourse-web" }
  )

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = "${local.environment}-concourse-web" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = "${local.environment}-concourse-web" })
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      aws_security_group.concourse_web.id,
      aws_security_group.concourse_vpc_endpoints.id,
    ]
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }
}
