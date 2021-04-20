resource "aws_iam_role" "concourse_web" {
  name               = "${local.environment}-concourse-web"
  assume_role_policy = data.aws_iam_policy_document.concourse_web.json

  tags = merge(
    local.common_tags,
    { Name = "${local.environment}-concourse-web" }
  )
}

// not convinced this is actually needed, in terms of the perms/TR it supplies
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

data "aws_iam_policy_document" "concourse_web" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "concourse_worker" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "concourse_worker_autoscaling" {
  statement {
    actions = [
      "autoscaling:SetInstanceHealth"
    ]

    resources = [
      aws_autoscaling_group.worker.arn
    ]
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
