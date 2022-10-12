
locals {
  //security groups
  
  list_of_rules = toset(flatten([
    for sg in var.security_groups : [
      for rules in sg.list_of_rules : [{
        name : rules.name
        type : rules.type
        description : rules.description,
        protocol : rules.protocol,
        from_port : rules.from_port,
        to_port : rules.to_port,
        cidr_blocks : rules.cidr_blocks,
        security_group_name : sg.name
      }]
  ]]))

// acm && route 53
alias = "${var.name}-${var.environment}"

  acm_certificate = {
    name              = "${var.acm_certificate.name}_${var.environment}_${var.name}"
    domain_name       = join(".", [local.alias, data.aws_route53_zone.dns.name])
    validation_method = var.acm_certificate.validation_method

  }
  route53_record = {
    ttl     = var.acm_certificate.ttl
    zone_id = data.aws_route53_zone.dns.zone_id
  }

  route53_alias = {
    name    = join(".", [local.alias, data.aws_route53_zone.dns.name])
    type    = var.acm_certificate.route53_record_type
    zone_id = data.aws_route53_zone.dns.zone_id
    alias = {
      name                   = aws_lb.application-lb.dns_name
      zone_id                = aws_lb.application-lb.zone_id
      evaluate_target_health = var.acm_certificate.evaluate_target_health
    }
  }

  //load balancer
  load_balancer = {
    name               = var.load_balancer.name
    internal           = var.load_balancer.internal
    load_balancer_type = var.load_balancer.load_balancer_type
    security_groups_list = flatten([
      for sg_lb in var.load_balancer.security_groups :
      aws_security_group.security_groups["${sg_lb}"].id
    ])
    subnets_list = flatten([
      for subnet in var.load_balancer.subnets :
      aws_subnet.subnets["${subnet}"].id
    ])
  }

  lb_target_group = {
    name        = "${var.load_balancer.lb_target_group.name}-${var.name}-${var.environment}"
    port        = var.load_balancer.lb_target_group.port
    vpc_id      = aws_vpc.vpcs.id
    protocol    = var.load_balancer.lb_target_group.protocol
    health_check = {
      enabled  = var.load_balancer.lb_target_group.health_check.enable
      path     = var.load_balancer.lb_target_group.health_check.path
      interval = var.load_balancer.lb_target_group.health_check.interval
      port     = var.load_balancer.lb_target_group.health_check.port
      protocol = var.load_balancer.lb_target_group.health_check.protocol
      matcher  = var.load_balancer.lb_target_group.health_check.matcher
    }
  }


  lb_listener = flatten([
    for listener in var.load_balancer.lb_listener : [{
      name : listener.name
      port : listener.port,
      protocol : listener.protocol,
      default_action_type : listener.default_action_type,
      target_group_arn : listener.target_group_arn != null ? aws_lb_target_group.app-lb-tg.arn : null,
      ssl_policy : listener.ssl_policy != null ? listener.ssl_policy : null,
      certificate_arn : listener.certificate_arn != null ? aws_acm_certificate.lb-https.arn : null,
      redirect : listener.redirect
    }]

  ])

//autoscaling group
subnets_list = flatten([
  for subnet in var.asg.autoscaling_group.vpc_zone_identifier :
  aws_subnet.subnets["${subnet}"].id
])

security_group_list = flatten([
  for sg in var.asg.launch_template.security_groups :
  aws_security_group.security_groups["${sg}"].id
])

}
