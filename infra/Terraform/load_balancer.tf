resource "aws_lb" "url_shortener_lb" {
  name               = "url-shortener-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
  tags = {
    Name = "URL Shortener Load Balancer"
  }
}

resource "aws_lb_target_group" "url_shortener_tg" {
  name     = "url-shortener-tg"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.url_shortener_vpc.id

  health_check {
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = {
    Name = "URL Shortener Target Group"
  }
}

resource "aws_lb_listener" "url_shortener_listener" {
  load_balancer_arn = aws_lb.url_shortener_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.url_shortener_tg.arn
  }
}
