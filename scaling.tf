resource "aws_subnet" "tidybase_lb_subnet_1" {
  vpc_id            = aws_vpc.tidybase_network.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tidybase-lb-1-public"
  }
}

resource "aws_subnet" "tidybase_lb_subnet_2" {
  vpc_id            = aws_vpc.tidybase_network.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "tidybase-lb-2-public"
  }
}

resource "aws_autoscaling_group" "tidybase_autoscaling" {
  name                 = "tidybase-scaling"
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.tidybase.name
  vpc_zone_identifier = [
    aws_subnet.tidybase_compute_subnet.id
  ]
}

resource "aws_lb" "tidybase_lb" {
  name               = "tidybase-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tidybase_compute_security_group.id]
  subnets = [
    aws_subnet.tidybase_lb_subnet_1.id,
    aws_subnet.tidybase_lb_subnet_2.id
  ]
}

resource "aws_lb_target_group" "tidybase" {
  name     = "tidybase"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.tidybase_network.id
}

resource "aws_autoscaling_attachment" "tidybase" {
  autoscaling_group_name = aws_autoscaling_group.tidybase_autoscaling.id
  lb_target_group_arn    = aws_lb_target_group.tidybase.arn
}

resource "aws_lb_listener" "tidybase_lb_listener" {
  load_balancer_arn = aws_lb.tidybase_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tidybase.arn
  }
}

output "lb_dns" {
  value = "http://${aws_lb.tidybase_lb.dns_name}"
}