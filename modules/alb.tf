resource "aws_lb" "application-lb" {
  provider           = aws
  name               = "${local.load_balancer.name}-${var.name}-${var.environment}"
  internal           = local.load_balancer.internal
  load_balancer_type = local.load_balancer.load_balancer_type
  security_groups    = local.load_balancer.security_groups_list
  subnets            = local.load_balancer.subnets_list
  tags = {
    Name    = "${local.load_balancer.name}-${var.environment}-${var.name}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "app-lb-tg" {
  provider = aws
  name     = local.lb_target_group.name
  port     = local.lb_target_group.port
  vpc_id   = local.lb_target_group.vpc_id
  protocol = local.lb_target_group.protocol
  health_check {
    enabled  = local.lb_target_group.health_check.enabled
    path     = local.lb_target_group.health_check.path
    interval = local.lb_target_group.health_check.interval
    port     = local.lb_target_group.health_check.port
    protocol = local.lb_target_group.health_check.protocol
    matcher  = local.lb_target_group.health_check.matcher
  }
  tags = {
    Name    = local.lb_target_group.name
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_lb_listener" "lb-listener-http" {
  provider          = aws
  load_balancer_arn = aws_lb.application-lb.arn
  for_each = {
    for listener in local.lb_listener : listener.name => listener
  }
  port            = each.value.port
  protocol        = each.value.protocol
  ssl_policy      = each.value.ssl_policy
  certificate_arn = each.value.certificate_arn

  default_action {
    type             = each.value.default_action_type
    target_group_arn = each.value.target_group_arn
    dynamic "redirect" {
      for_each = each.value.redirect != 0 ? each.value.redirect : null
      content {
        status_code = redirect.value.status_code
        port        = redirect.value.port
        protocol    = redirect.value.protocol
      }
    }
  }
  tags = {
    Name    = "${each.value.name}_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}
