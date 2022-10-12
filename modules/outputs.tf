output "alb_dns_name" {
  description = "The DNS name of the application load balancer in timeoffec2"
  value       = aws_lb.application-lb.dns_name
}

output "url" {
  description = "The url of the dns server"
  value       = aws_route53_record.record.fqdn
}
