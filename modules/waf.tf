resource "aws_wafregional_ipset" "ipset" {
  name = var.waf.ip_set.name

}

resource "aws_wafregional_rule" "aplication-firewall" {
  depends_on  = [aws_wafregional_ipset.ipset]
  name        = var.waf.waf_rule.name
  metric_name = var.waf.waf_rule.metric_name

  predicate {
    data_id = aws_wafregional_ipset.ipset.id
    negated = var.waf.waf_rule.negated
    type    = var.waf.waf_rule.type
  }
  tags = {
    Name    = "${var.waf.waf_rule.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_wafregional_web_acl" "web-acl" {
  name        = var.waf.waf_acl.name
  metric_name = var.waf.waf_acl.metric_name

  default_action {
    type = var.waf.waf_acl.default_action
  }

  rule {
    action {
      type = var.waf.waf_acl.type
    }

    priority = var.waf.waf_acl.priority
    rule_id  = aws_wafregional_rule.aplication-firewall.id
  }
  tags = {
    Name    = "${var.waf.waf_acl.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_wafregional_web_acl_association" "acl-association" {
  resource_arn = aws_lb.application-lb.arn
  web_acl_id   = aws_wafregional_web_acl.web-acl.id
}



