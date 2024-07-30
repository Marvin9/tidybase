resource "aws_efs_file_system" "tidybase_efs" {
  creation_token = "tidybase"
  encrypted      = true

  tags = {
    Name = "tidybase"
  }
}

