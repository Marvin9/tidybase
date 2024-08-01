resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.tidybase_efs.id

  backup_policy {
    status = "ENABLED"
  }
}
