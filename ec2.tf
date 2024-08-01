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

resource "aws_launch_template" "tidybase_launch" {
  depends_on = [aws_efs_file_system.tidybase_efs, aws_ssm_parameter.tidybase_cloudwatch_agent_config]
  user_data = base64encode(templatefile(local.pocketbase_launch_script, {
    efs_id                      = aws_efs_file_system.tidybase_efs.id
    secret_id                   = var.tidybase_secret_name
    cloudwatch_agent_config_ssm = aws_ssm_parameter.tidybase_cloudwatch_agent_config.name
  }))
}

resource "aws_launch_configuration" "tidybase" {
  depends_on = [
    aws_launch_template.tidybase_launch,
    aws_security_group.tidybase_compute_security_group,
    aws_subnet.tidybase_compute_subnet,
    aws_efs_file_system.tidybase_efs,
    aws_ssm_parameter.tidybase_cloudwatch_agent_config
  ]

  image_id             = var.amazon_linux_2023_ami_id
  instance_type        = "t2.micro"
  key_name             = var.tidybase_compute_key_name
  iam_instance_profile = var.instance_profile

  user_data_base64 = base64encode(templatefile(local.pocketbase_launch_script, {
    efs_id                      = aws_efs_file_system.tidybase_efs.id
    secret_id                   = var.tidybase_secret_name
    cloudwatch_agent_config_ssm = aws_ssm_parameter.tidybase_cloudwatch_agent_config.name
  }))

  associate_public_ip_address = true

  lifecycle {
    create_before_destroy = true
  }

  security_groups = [aws_security_group.tidybase_compute_security_group.id]
}
