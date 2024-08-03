resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.tidybase_efs.id

  backup_policy {
    status = "ENABLED"
  }
}

resource "aws_s3_bucket" "tidybase_backups" {
  bucket        = "tidybase-backups"
  force_destroy = true

  tags = {
    Name = "tidybase-backups"
  }
}
resource "aws_s3_bucket_public_access_block" "tidybase_public_access_allow" {
  bucket = aws_s3_bucket.tidybase_backups.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "tidybase_backups_ownership_controls" {
  bucket     = aws_s3_bucket.tidybase_backups.id
  depends_on = [aws_s3_bucket_public_access_block.tidybase_public_access_allow]
  rule {
    object_ownership = "ObjectWriter"
  }
}

resource "aws_s3_bucket_acl" "tidybase_backups_acl" {
  depends_on = [aws_s3_bucket_ownership_controls.tidybase_backups_ownership_controls]
  bucket     = aws_s3_bucket.tidybase_backups.id
  acl        = "private"
}

resource "aws_s3_bucket_policy" "tidybase_backups_policy" {
  depends_on = [aws_s3_bucket.tidybase_backups, aws_s3_bucket_public_access_block.tidybase_public_access_allow]
  bucket     = aws_s3_bucket.tidybase_backups.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:*"
        ]
        Effect = "Allow"
        Resource = [
          "${aws_s3_bucket.tidybase_backups.arn}",
          "${aws_s3_bucket.tidybase_backups.arn}/*"
        ]
        Principal = "*"
      },
    ]
  })
}
