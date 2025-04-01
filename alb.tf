# security group
resource "aws_security_group" "alb_security_group" {
    name = "${local.tag}-alb-sg"
    vpc_id = aws_vpc.vpc.id

    depends_on = [ aws_vpc.vpc ]
}

resource "aws_vpc_security_group_ingress_rule" "alb_sg_ingress" {
    count = 2
    security_group_id = aws_security_group.alb_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port = [80, 443][count.index]
    to_port = [80, 443][count.index]

    depends_on = [ aws_security_group.alb_security_group ]
}

resource "aws_vpc_security_group_egress_rule" "alb_sg_egress" {
    security_group_id = aws_security_group.alb_security_group.id
    cidr_ipv4 = "0.0.0.0/0"
    ip_protocol = -1

    depends_on = [ aws_security_group.alb_security_group ]
}

# load balancer
resource "aws_lb" "alb" {
    name = "${local.tag}-alb"
    internal = false
    load_balancer_type = "application"
    security_groups = [ aws_security_group.alb_security_group.id ]
    subnets = aws_subnet.public_subnets[*].id
    ip_address_type = "ipv4"

    enable_deletion_protection = true

    depends_on = [ aws_subnet.public_subnets, aws_security_group.alb_security_group ]
}

# HTTP -> HTTPS redirect
resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"

    default_action {
        type = "redirect"
        redirect {
            protocol = "HTTPS"
            port = "443"
            status_code = "HTTP_301"
            query = "#{query}"
            path = "/#{path}"
            host = "#{host}"
        }
    }
    depends_on = [ aws_lb.alb ]
}

resource "aws_lb_listener_rule" "force_http_redirect" {
    listener_arn = aws_lb_listener.http.arn
    priority = 1

    action {
        type = "redirect"
        redirect {
            protocol = "HTTPS"
            port = "443"
            status_code = "HTTP_301"
            query = "#{query}"
            path = "/#{path}"
            host = "#{host}"
        }
    }
    condition {
        path_pattern {
            values = [ "*" ]
        }
    }
    tags = {
        Name = "force https redirect"
    }
}

# HTTPS certificate setup
resource "aws_lb_listener" "lb_routing" {
    load_balancer_arn = aws_lb.alb.arn
    port = 443
    protocol = "HTTPS"
    certificate_arn = var.alb_acm_certificate
    ssl_policy = "ELBSecurityPolicy-2016-08"

    default_action {
        type = "fixed-response"
        fixed_response {
            status_code = 400
            message_body = "not allowed"
            content_type = "text/plain"
        }
    }
    depends_on = [ aws_lb.alb ]
}
