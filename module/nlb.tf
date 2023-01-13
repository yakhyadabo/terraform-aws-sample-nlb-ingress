resource "aws_lb" "this" {
  name_prefix   = "${var.service_name}-"
  load_balancer_type = "network"
  subnets            = data.aws_subnets.public.ids

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "this" {
  for_each              = var.ports

  load_balancer_arn = aws_lb.this.arn

  protocol          = "TCP" #(TLS)
  port              = each.value

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }
}

resource "aws_lb_target_group" "this" {
  for_each = var.ports

  port        = each.value
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.main.id
  # target_type = "instance"

  depends_on = [
    aws_lb.this
  ]

  lifecycle {
    create_before_destroy = true
  }
}

data "template_file" "nginx" {
  template = file("${path.module}/file/nginx.sh")
}

resource "aws_launch_configuration" "service" {
  name_prefix             = "${var.service_name}-${var.environment}-"
  image_id                = data.aws_ami.ubuntu.id
  instance_type           = "t2.micro"
  security_groups         = [aws_security_group.this.id]
  key_name                = var.key_name

  user_data               = data.template_file.nginx.rendered

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "service" {
  # for_each              = var.ports
  name_prefix   = "${var.service_name}-${var.environment}-"
  launch_configuration      = aws_launch_configuration.service.id
  min_size                  = 1
  max_size                  = length(data.aws_subnets.private.ids)
  desired_capacity          = length(data.aws_subnets.private.ids)
  health_check_type         = "ELB"
  termination_policies      = ["OldestLaunchConfiguration"]
  vpc_zone_identifier       = data.aws_subnets.private.ids
  wait_for_capacity_timeout = "20m"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_attachment" "target" {
  for_each = var.ports
  autoscaling_group_name = aws_autoscaling_group.service.id
  lb_target_group_arn   = aws_lb_target_group.this[each.key].arn
}