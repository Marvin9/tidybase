resource "aws_launch_template" "tidybase_launch" {
  depends_on = [aws_efs_file_system.tidybase_efs]
  user_data = base64encode(templatefile(local.pocketbase_launch_script, {
    efs_id = aws_efs_file_system.tidybase_efs.id
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
