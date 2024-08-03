
resource "aws_lb" "tidybase_lb" {
  name               = "tidybase-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tidybase_lb.id]
  subnets            = [aws_subnet.tidybase_lb_1.id, aws_subnet.tidybase_lb_2.id]
}

resource "aws_lb_listener" "tidybase_lb_listener" {
  load_balancer_arn = aws_lb.tidybase_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tidybase_target_group.arn
  }
}

resource "aws_lb_target_group" "tidybase_target_group" {
  name     = "tidybase-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.tidybase_network.id

  health_check {
    enabled = true
    path    = "/api/health"
    port    = 80
  }

  deregistration_delay = 10
}

output "lb_dns" {
  value = "http://${aws_lb.tidybase_lb.dns_name}"
}
