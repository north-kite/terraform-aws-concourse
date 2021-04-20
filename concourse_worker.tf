data "template_file" "concourse_worker_userdata" {
  template = file(format("%s/files/concourse_worker/userdata.tf2", path.module))
  vars = {
    env = local.environment
  }
}

resource "aws_launch_template" "concourse_worker" {
  name_prefix                          = "${local.name}-concourse-worker"
  image_id                             = var.ami_id
  instance_type                        = var.concourse_worker_conf.instance_type
  instance_initiated_shutdown_behavior = "terminate"
  tags                                 = merge(local.common_tags, { Name = local.name })

  user_data = base64encode(data.template_file.concourse_worker_userdata.rendered)

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_type           = "io1"
      iops                  = 2000
      volume_size           = 100
    }
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    no_device   = true
  }

  iam_instance_profile {
    arn = aws_iam_instance_profile.concourse_worker.arn
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.common_tags, { Name = local.name })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = local.name })
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true

    security_groups = [
      aws_security_group.concourse_worker.id
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
