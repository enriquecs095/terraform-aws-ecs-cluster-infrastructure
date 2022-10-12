module "ecs-cluster" {
  source      = "./modules"
  name        = var.name
  environment = var.environment
  vpc = var.vpc
  subnets = var.subnets
  security_groups = var.security_groups
  load_balancer = var.load_balancer
  asg = var.asg
  acm_certificate = var.acm_certificate
  ecs = var.ecs
  waf = var.waf
  devops_name  = var.devops_name
  project_name = var.project_name

}

