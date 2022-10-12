#ACM CONFIGURATION
#Get already, publicly configured Hosted Zone on Route53 - MUST EXIST
data "aws_route53_zone" "dns" {
  provider = aws
  name     = var.acm_certificate.dns_name
}

#Creates ACM certificate and requests validation via DNS(Route53)
resource "aws_acm_certificate" "lb-https" {
  provider          = aws
  domain_name       = local.acm_certificate.domain_name
  validation_method = local.acm_certificate.validation_method
  tags = {
    Name    = local.acm_certificate.name
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

#Validate ACM issued certificate via Route53
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws
  certificate_arn         = aws_acm_certificate.lb-https.arn
  for_each                = aws_route53_record.cert-validation
  validation_record_fqdns = [aws_route53_record.cert-validation[each.key].fqdn]
}

#Create record in hosted zone for ACM  Certificate Domain verification
resource "aws_route53_record" "cert-validation" {
  provider = aws
  for_each = {
    for val in aws_acm_certificate.lb-https.domain_validation_options : val.domain_name => {
      name   = val.resource_record_name
      record = val.resource_record_value
      type   = val.resource_record_type
    }
  }
  name    = each.value.name
  records = [each.value.record]
  ttl     = local.route53_record.ttl
  type    = each.value.type
  zone_id = local.route53_record.zone_id
}

#Create Alias record towards ALB from Route53
resource "aws_route53_record" "record" {
  provider = aws
  name     = local.route53_alias.name
  type     = local.route53_alias.type
  zone_id  = local.route53_alias.zone_id
  alias {
    name                   = local.route53_alias.alias.name
    zone_id                = local.route53_alias.alias.zone_id
    evaluate_target_health = local.route53_alias.alias.evaluate_target_health
  }
}
