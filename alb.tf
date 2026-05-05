# Define the AL itself
resource "aws_lb" "web_alb" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.public_entrypoint[*].id

  enable_deletion_protection = false

  tags = {
    Environment = "Dev"
  }
}

# Define the ALB Target Group
resource "aws_lb_target_group" "web_server_target_alb_group" {
  name_prefix     = "web-"
  port            = 5000
  protocol        = "HTTP"
  vpc_id          = aws_vpc.main_vpc.id

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb_listener" "web_alb_forwarder" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_server_target_alb_group.arn
  }

  lifecycle {
    create_before_destroy = true
  }
}