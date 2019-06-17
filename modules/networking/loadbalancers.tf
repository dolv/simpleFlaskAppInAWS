### ALB

resource "aws_lb" "app" {
  name               = "app-front-lb"
  load_balancer_type = "application"
  subnets            = [
    for subnet in aws_subnet.public:
          subnet.id
    ]
  security_groups    = [
    aws_security_group.lb.id]

  depends_on = [aws_subnet.public, aws_security_group.lb]
}

resource "aws_alb_target_group" "app" {
  name        = "app-front-lb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  depends_on = [aws_vpc.main]
}

# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_lb.app.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.app.id
    type             = "forward"
  }

  depends_on = [aws_lb.app, aws_alb_target_group.app]
}