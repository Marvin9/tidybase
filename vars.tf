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
}

variable "tidybase_compute_key_name" {
  type    = string
  default = "pocketbase-ec2"
}
