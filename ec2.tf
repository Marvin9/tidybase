resource "aws_subnet" "tidybase_compute_subnet" {
  vpc_id     = aws_vpc.tidybase_network.id
  cidr_block = "10.0.0.0/24"

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

resource "aws_launch_template" "tidybase_launch" {
  depends_on = [aws_efs_file_system.tidybase_efs, aws_ssm_parameter.tidybase_cloudwatch_agent_config]
  user_data = base64encode(templatefile(local.pocketbase_launch_script, {
    efs_id                      = aws_efs_file_system.tidybase_efs.id
    secret_id                   = var.tidybase_secret_name
    cloudwatch_agent_config_ssm = aws_ssm_parameter.tidybase_cloudwatch_agent_config.name
  }))
}

resource "aws_instance" "tidybase_compute" {
  depends_on = [
    aws_launch_template.tidybase_launch,
    aws_security_group.tidybase_compute_security_group,
    aws_subnet.tidybase_compute_subnet,
  ]
  ami                    = var.amazon_linux_2023_ami_id
  instance_type          = "t2.micro"
  key_name               = var.tidybase_compute_key_name
  vpc_security_group_ids = [aws_security_group.tidybase_compute_security_group.id]
  subnet_id              = aws_subnet.tidybase_compute_subnet.id
  iam_instance_profile   = var.instance_profile

  launch_template {
    id = aws_launch_template.tidybase_launch.id
  }

  tags = {
    Name = "tidybase"
  }
}

resource "aws_eip" "tidybase_compute_eip" {
  instance = aws_instance.tidybase_compute.id
}

output "instance_dns" {
  depends_on = [aws_eip.tidybase_compute_eip]
  value      = aws_eip.tidybase_compute_eip.public_dns
}
