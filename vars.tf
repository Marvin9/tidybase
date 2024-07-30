variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "amazon_linux_2023_ami_id" {
  type    = string
  default = "ami-0427090fd1714168b"
}

locals {
  pocketbase_launch_script = "${path.root}/scripts/launch.sh"
  nfs_port                 = 2049
}

variable "tidybase_compute_key_name" {
  type    = string
  default = "pocketbase-ec2"
}

variable "tidybase_secret_name" {
  type    = string
  default = "test/tidybase"
}

variable "ADMIN_EMAIL" {
  description = "pocketbase initial admin email"
  type        = string
}

variable "ADMIN_PASSWORD" {
  description = "pocketbase initial admin password"
  type        = string
  sensitive   = true
}

variable "instance_profile" {
  type    = string
  default = "LabInstanceProfile"
}