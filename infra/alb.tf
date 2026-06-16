# --- ALB do Backend (frontend vai via CloudFront) ---
resource "aws_lb" "backend" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_backend.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags               = merge(local.common_tags, { Name = "${local.name_prefix}-alb-backend" })
}

resource "aws_lb_target_group" "backend" {
  name     = local.tg_name
  port     = var.backend_node_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = var.health_check_path
    port                = tostring(var.backend_node_port)
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
  tags = merge(local.common_tags, { Name = "${local.name_prefix}-tg-backend" })
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "backend_https" {
  load_balancer_arn = aws_lb.backend.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.api.certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}
