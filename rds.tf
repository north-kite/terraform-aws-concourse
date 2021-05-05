resource "aws_db_subnet_group" "concourse_cluster" {
  subnet_ids = local.vpc.private_subnets
}

resource "aws_kms_key" "concourse_aurora" {
  enable_key_rotation     = true
  deletion_window_in_days = 7
  tags                    = merge(local.common_tags, { Name = "${local.name}-db-key", ProtectsSensitiveData = true })
}

resource "aws_kms_alias" "concourse_aurora" {
  name          = "alias/${local.environment}-concourse-db-key"
  target_key_id = aws_kms_key.concourse_aurora.key_id
}

//data "aws_db_cluster_snapshot" "concourse_cluster" {
//  db_cluster_identifier = local.name
//  most_recent           = true
//}

resource "aws_rds_cluster" "cluster" {
  cluster_identifier        = "${local.environment}-concourse"
  engine                    = var.concourse_db_conf.engine
  engine_version            = var.concourse_db_conf.engine_version
  availability_zones        = local.zone_names
  database_name             = local.name
  master_username           = var.concourse_sec.concourse_db_username
  master_password           = var.concourse_sec.concourse_db_password
  backup_retention_period   = 14
  preferred_backup_window   = var.concourse_db_conf.preferred_backup_window
  apply_immediately         = true
  db_subnet_group_name      = aws_db_subnet_group.concourse_cluster.id
  final_snapshot_identifier = "${local.name}-final-snapshot"
  skip_final_snapshot       = true
  //  snapshot_identifier       = data.aws_db_cluster_snapshot.concourse_cluster.id
  storage_encrypted      = true
  kms_key_id             = aws_kms_key.concourse_aurora.arn
  vpc_security_group_ids = [aws_security_group.concourse_db.id]
  tags                   = merge(local.common_tags, { Name = "${local.name}-db" })

  lifecycle {
    ignore_changes = [
      engine_version,
      //      snapshot_identifier,
    ]
  }
}

resource "aws_rds_cluster_instance" "cluster" {
  count              = var.concourse_db_conf.db_count
  identifier_prefix  = "${local.name}-${local.zone_names[count.index]}-"
  engine             = aws_rds_cluster.cluster.engine
  engine_version     = aws_rds_cluster.cluster.engine_version
  availability_zone  = local.zone_names[count.index]
  cluster_identifier = aws_rds_cluster.cluster.id
  instance_class     = var.concourse_db_conf.instance_type
  tags               = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}
