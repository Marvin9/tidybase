resource "aws_launch_configuration" "tidybase_compute_small" {
  image_id                    = var.amazon_linux_2023_ami_id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile
  user_data_base64 = base64encode(templatefile(local.pocketbase_launch_script, {
    efs_id                      = aws_efs_file_system.tidybase_efs.id
    secret_id                   = var.tidybase_secret_name
    cloudwatch_agent_config_ssm = aws_ssm_parameter.tidybase_cloudwatch_agent_config.name
    efs_dns                     = aws_efs_file_system.tidybase_efs.dns_name
  }))
  key_name        = var.tidybase_compute_key_name
  security_groups = [aws_security_group.tidybase_compute_security_group.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "tidybase_small_asg" {
  name                 = "tidybase-small-asg"
  depends_on           = [aws_efs_file_system.tidybase_efs]
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.tidybase_compute_small.name
  vpc_zone_identifier = [
    aws_subnet.tidybase_compute_subnet.id
  ]

  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "tidybase_small_asg"
  }
}
