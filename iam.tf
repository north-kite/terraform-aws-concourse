resource "aws_iam_role" "concourse_web" {
  name               = "${local.environment}-concourse-web"
  assume_role_policy = data.aws_iam_policy_document.concourse_web.json

  tags = merge(
    local.common_tags,
    { Name = "${local.environment}-concourse-web" }
  )
}

resource "aws_iam_role" "concourse_worker" {
  name = "${local.environment}-concourse-worker"

  tags = merge(
    local.common_tags,
    { Name = "${local.environment}-concourse-worker" }
  )
  assume_role_policy = data.aws_iam_policy_document.concourse_worker.json
}

resource "aws_iam_instance_profile" "concourse_web" {
  name = aws_iam_role.concourse_web.name
  role = aws_iam_role.concourse_web.id
}

resource "aws_iam_instance_profile" "concourse_worker" {
  name = aws_iam_role.concourse_worker.name
  role = aws_iam_role.concourse_worker.name
}

resource "aws_iam_role_policy_attachment" "concourse_web_cloudwatch_logging" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.concourse_web.id
}

resource "aws_iam_role_policy_attachment" "concourse_worker_cloudwatch_logging" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.concourse_worker.id
}

resource "aws_iam_role_policy_attachment" "concourse_web_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.concourse_web.id
}

resource "aws_iam_role_policy_attachment" "concourse_worker_ssm" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  role       = aws_iam_role.concourse_worker.id
}

resource "aws_iam_role_policy_attachment" "concourse_web_secrets_manager" {
  policy_arn = aws_iam_policy.concourse_web_secrets_manager.arn
  role       = aws_iam_role.concourse_web.id
}

resource "aws_iam_policy" "concourse_web_secrets_manager" {
  name        = "${local.environment}-concourse-web-secrets-manager"
  description = "Allow concourse-web Instances to access Secrets Manager"
  policy      = data.aws_iam_policy_document.concourse_web_secrets_manager.json
}

data "aws_iam_policy_document" "concourse_web_secrets_manager" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.concourse_sec.session_signing_key_private_secret_arn,
      var.concourse_sec.session_signing_key_public_secret_arn,
      var.concourse_sec.tsa_host_key_private_secret_arn,
      var.concourse_sec.tsa_host_key_public_secret_arn,
      var.concourse_sec.worker_key_private_secret_arn,
      var.concourse_sec.worker_key_public_secret_arn,
    ]
  }
}

resource "aws_iam_role_policy_attachment" "concourse_worker_secrets_manager" {
  policy_arn = aws_iam_policy.concourse_worker_secrets_manager.arn
  role       = aws_iam_role.concourse_worker.id
}

resource "aws_iam_policy" "concourse_worker_secrets_manager" {
  name        = "${local.environment}-concourse-worker-secrets-manager"
  description = "Allow concourse-worker Instances to access Secrets Manager"
  policy      = data.aws_iam_policy_document.concourse_worker_secrets_manager.json
}

data "aws_iam_policy_document" "concourse_worker_secrets_manager" {
  statement {
    actions = ["secretsmanager:GetSecretValue"]

    resources = [
      var.concourse_sec.tsa_host_key_public_secret_arn,
      var.concourse_sec.worker_key_private_secret_arn,
    ]
  }
}

data "aws_iam_policy_document" "concourse_web" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "concourse_worker" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "concourse_worker_autoscaling" {
  statement {
    actions = ["autoscaling:SetInstanceHealth"]

    resources = [aws_autoscaling_group.worker.arn]
  }
}

resource "aws_iam_policy" "concourse_worker_autoscaling" {
  name        = "${local.environment}-concourse-worker-asg"
  description = "Change Concourse Worker's Instance Health"
  policy      = data.aws_iam_policy_document.concourse_worker_autoscaling.json
}

resource "aws_iam_role_policy_attachment" "concourse_worker_autoscaling" {
  policy_arn = aws_iam_policy.concourse_worker_autoscaling.arn
  role       = aws_iam_role.concourse_worker.id
}

data "aws_iam_policy_document" "concourse_tag_ec2" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:CreateTags"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "concourse_tag_ec2" {
  name        = "${local.name}EC2"
  description = "Change Concourse Worker's Tags"
  policy      = data.aws_iam_policy_document.concourse_tag_ec2.json
}

resource "aws_iam_role_policy_attachment" "concourse_tag_ec2" {
  policy_arn = aws_iam_policy.concourse_tag_ec2.arn
  role       = aws_iam_role.concourse_worker.id
}

data "aws_iam_policy_document" "concourse_worker_assume_ci_role" {
  statement {
    sid = "AllowConcourseWorkerAssumeCIRole"
    actions = [
      "sts:AssumeRole",
    ]

    resources = ["arn:aws:iam::${local.account}:role/ci"]
  }
}

resource "aws_iam_policy" "concourse_worker_assume_ci_role" {
  name        = "${local.environment}-concourse-worker-assume-ci-role"
  description = "Allow Concourse Workers to assume the CI Role"
  policy      = data.aws_iam_policy_document.concourse_worker_assume_ci_role.json
}

resource "aws_iam_role_policy_attachment" "concourse_worker_assume_ci_role" {
  policy_arn = aws_iam_policy.concourse_worker_assume_ci_role.arn
  role       = aws_iam_role.concourse_worker.id
}
