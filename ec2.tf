resource "aws_subnet" "tidybase_compute_subnet" {
  vpc_id            = aws_vpc.tidybase_network.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "tidybase-compute-public"
  }
}


resource "aws_security_group" "tidybase_compute_security_group" {
  vpc_id = aws_vpc.tidybase_network.id
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_http_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tidybase_compute_allow_all_http_egress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_ssh_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tidybase_compute_allow_all_ssh_egress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "tidybase_compute_allow_all_https_ingress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tidybase_compute_allow_all_https_egress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "tidybase_compute_allow_only_private_subnet_nfs_egress" {
  security_group_id = aws_security_group.tidybase_compute_security_group.id
  cidr_ipv4         = aws_subnet.tidybase_efs_subnet.cidr_block
  from_port         = local.nfs_port
  to_port           = local.nfs_port
  ip_protocol       = "tcp"
}

resource "aws_ssm_parameter" "tidybase_cloudwatch_agent_config" {
  description = "cloudwatch agent config for tidybase ec2 logs"
  name        = "/tidybase/agent/config"
  type        = "String"
  value       = file("${path.root}/cloudwatch-agent-config.json")
}
