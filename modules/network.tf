#Create VPCs
resource "aws_vpc" "vpcs" {
  provider             = aws
  cidr_block           = var.vpc.cidr_block
  enable_dns_support   = var.vpc.dns_support
  enable_dns_hostnames = var.vpc.dns_hostname
  tags = {
    Name    = "vpc_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

#Create internet gateways
resource "aws_internet_gateway" "igws" {
  provider = aws
  vpc_id   = aws_vpc.vpcs.id
  tags = {
    Name    = "gateway_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

#Create subnets
resource "aws_subnet" "subnets" {
  provider = aws
  vpc_id   = aws_vpc.vpcs.id
  for_each = {
    for subnet in var.subnets : subnet.name => subnet
  }
  availability_zone = each.value.availability_zone
  cidr_block        = each.value.cidr_block
  tags = {
    Name    = "${each.value.name}_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

#Create route tables
resource "aws_route_table" "internet-route" {
  provider = aws
  vpc_id   = aws_vpc.vpcs.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igws.id
  }
  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name    = "route_table_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

#Overwrite default route table of VPCs with our route table entries 
resource "aws_main_route_table_association" "set-master-default-route-tables" {
  provider       = aws
  vpc_id         = aws_vpc.vpcs.id
  route_table_id = aws_route_table.internet-route.id
}

#Create SG
resource "aws_security_group" "security_groups" {
  provider = aws
  for_each = {
    for sg in var.security_groups : sg.name => sg
  }
  name        = "${each.value.name}_${var.environment}"
  description = each.value.description
  vpc_id      = aws_vpc.vpcs.id
  tags = {
    Name    = "${each.value.name}_${var.name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_security_group_rule" "ingress_egress_rules" {
  for_each = {
    for rules in local.list_of_rules : rules.name => rules
    if length(rules) > 0
  }
  type              = each.value.type
  description       = each.value.description
  protocol          = each.value.protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_blocks       = each.value.cidr_blocks
  security_group_id = aws_security_group.security_groups[each.value.security_group_name].id

}
