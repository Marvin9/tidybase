resource "aws_subnet" "tidybase_efs_subnet" {
  vpc_id            = aws_vpc.tidybase_network.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone[0]

  tags = {
    Name = "tidybase-efs-private"
  }
}

resource "aws_security_group" "tidybase_efs_security_group" {
  vpc_id = aws_vpc.tidybase_network.id
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_efs_allow_only_public_subnet_nfs_ingress" {
  security_group_id = aws_security_group.tidybase_efs_security_group.id
  cidr_ipv4         = aws_subnet.tidybase_compute_subnet.cidr_block
  from_port         = local.nfs_port
  to_port           = local.nfs_port
  ip_protocol       = "tcp"
}

resource "aws_efs_file_system" "tidybase_efs" {
  creation_token         = "tidybase"
  encrypted              = true
  availability_zone_name = var.availability_zone[0]

  tags = {
    Name = "tidybase"
  }
}

resource "aws_efs_replication_configuration" "tidybase_efs_replication" {
  source_file_system_id = aws_efs_file_system.tidybase_efs.id

  destination {
    region                 = var.aws_region
    availability_zone_name = var.availability_zone[1]
  }
}

resource "aws_efs_mount_target" "tidybase_efs_mount" {
  file_system_id  = aws_efs_file_system.tidybase_efs.id
  subnet_id       = aws_subnet.tidybase_efs_subnet.id
  security_groups = [aws_security_group.tidybase_efs_security_group.id]
}

output "efs_id" {
  value = aws_efs_file_system.tidybase_efs.id
}
