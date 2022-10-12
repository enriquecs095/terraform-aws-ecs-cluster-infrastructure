output "alb_dns_name_ecs" {
  description = "The DNS name of the application load balancer"
  value       = module.ecs-cluster.alb_dns_name
}

output "url_ecs" {
  description = "The url of the dns server for the web application"
  value       =  module.ecs-cluster.url
}