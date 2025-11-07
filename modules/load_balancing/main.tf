resource "aws_security_group" "public_alb_sg" {
  vpc_id = var.vpc_id
  ingress { 
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
        }
  egress { 
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = var.public_subnets_cidrs
        }
  tags = { Name = "Public-ALB-SG" }
}

resource "aws_security_group" "internal_alb_sg" {
  vpc_id = var.vpc_id
  ingress { 
            from_port = 80
            to_port = 80
            protocol = "tcp"
            cidr_blocks = var.public_subnets_cidrs
          }
  egress {
            from_port = 5000
            to_port = 5000
            protocol = "tcp"
            cidr_blocks = var.private_subnets_cidrs
            }
  tags = { Name = "Internal-ALB-SG" }
}

resource "aws_lb" "public_alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_alb_sg.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "public_tg" {
  name        = "public-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
                 path = "/"
                 port = "80"
            } # Health check Nginx on port 80
}

resource "aws_lb_listener" "public_listener" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "public_tg_att" {
  count            = length(var.proxy_instance_ids)
  target_group_arn = aws_lb_target_group.public_tg.arn
  target_id        = var.proxy_instance_ids[count.index]
}

resource "aws_lb" "internal_alb" {
  name               = "in-alb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.internal_alb_sg.id]
  subnets            = var.private_subnets
}

resource "aws_lb_target_group" "internal_tg" {
  name        = "internal-tg"
  port        = 5000 # Flask App Port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"
  health_check {
        path = "/"
        port = "5000"
        } # Health check Flask on port 5000
}

resource "aws_lb_listener" "internal_listener" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port              = 80 # Nginx proxies will hit this port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.internal_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "internal_tg_att" {
  count            = length(var.backend_instance_ids)
  target_group_arn = aws_lb_target_group.internal_tg.arn
  target_id        = var.backend_instance_ids[count.index]
}

