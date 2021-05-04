locals {
  //  logger_bootstrap_file = templatefile(
  //    "${path.module}/templates/logger_bootstrap.sh",
  //    {
  //      cloudwatch_agent_config_ssm_parameter = aws_ssm_parameter.cloudwatch_agent_config_worker.name
  //      https_proxy                           = var.proxy.https_proxy
  //    }
  //  )

  worker_service_env_vars = merge(
    {
      CONCOURSE_EPHEMERAL = true
      CONCOURSE_WORK_DIR  = "/opt/concourse"

      CONCOURSE_TSA_HOST               = "${aws_lb.internal_lb.dns_name}:2222"
      CONCOURSE_TSA_PUBLIC_KEY         = "/etc/concourse/tsa_host_key.pub"
      CONCOURSE_TSA_WORKER_PRIVATE_KEY = "/etc/concourse/worker_key"
      CONCOURSE_CERTS_DIR              = "/etc/ssl/certs"
      CONCOURSE_GARDEN_NETWORK_POOL    = var.concourse_worker_conf.garden_network_pool
      CONCOURSE_GARDEN_MAX_CONTAINERS  = var.concourse_worker_conf.garden_max_containers
      CONCOURSE_LOG_LEVEL              = var.concourse_worker_conf.log_level

      //      HTTP_PROXY  = var.proxy.http_proxy
      //      HTTPS_PROXY = var.proxy.https_proxy
      //      NO_PROXY    = var.proxy.no_proxy
      //      http_proxy  = var.proxy.http_proxy
      //      https_proxy = var.proxy.https_proxy
      //      no_proxy    = var.proxy.no_proxy
    },
    //    var.worker.environment_override
  )

  worker_systemd_file = templatefile(
    "${path.module}/files/concourse_worker/worker_systemd",
    {
      environment_vars = local.worker_service_env_vars
    }
  )

  worker_upstart_file = templatefile(
    "${path.module}/files/concourse_worker/worker_upstart",
    {
      environment_vars = local.worker_service_env_vars
    }
  )

  worker_bootstrap_file = templatefile(
    "${path.module}/files/concourse_worker/worker_bootstrap.sh",
    {
      aws_default_region             = data.aws_region.current.name
      tsa_host_key_public_secret_arn = var.concourse_sec.tsa_host_key_public_secret_arn
      worker_key_private_secret_arn  = var.concourse_sec.worker_key_private_secret_arn
      concourse_version              = var.concourse_version
      //      http_proxy              = var.proxy.http_proxy
      //      https_proxy             = var.proxy.https_proxy
      //      no_proxy                = var.proxy.no_proxy
      name = local.name
    }
  )

    healthcheck_file = templatefile(
      "${path.module}/files/concourse_worker/healthcheck.sh",
      {}
    )

}

data "template_cloudinit_config" "worker_bootstrap" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = "package_update: true"
  }

  part {
    content_type = "text/cloud-config"
    content      = "package_upgrade: true"
  }

  part {
    content_type = "text/cloud-config"
    content      = <<EOF
packages:
  - aws-cli
  - jq
EOF
  }

  part {
    content_type = "text/cloud-config"

    content = <<EOF
write_files:
  - encoding: b64
    content: ${base64encode(local.worker_upstart_file)}
    owner: root:root
    path: /etc/init/concourse-worker.conf
    permissions: '0644'
  - encoding: b64
    content: ${base64encode(local.worker_systemd_file)}
    owner: root:root
    path: /etc/systemd/system/concourse-worker.service
    permissions: '0644'
EOF
  }

  //  - encoding: b64
  //    content: ${base64encode(local.healthcheck_file)}
  //    owner: root:root
  //    path: /home/root/healthcheck.sh
  //    permissions: '0700'

  part {
    content_type = "text/x-shellscript"
    content      = local.worker_bootstrap_file
  }
  //
  //  part {
  //    content_type = "text/x-shellscript"
  //    content      = local.logger_bootstrap_file
  //  }
}
