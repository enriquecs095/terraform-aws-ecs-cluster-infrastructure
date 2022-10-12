data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = [var.asg.launch_template.ami_name]
  }
}

resource "aws_launch_template" "template-instance" {
  name_prefix   = var.asg.launch_template.name
  image_id      = data.aws_ami.ami.id
  instance_type = var.asg.launch_template.instance_type
  user_data = filebase64(var.asg.launch_template.user_data)
  key_name = var.asg.launch_template.key_pair

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = local.security_group_list
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name    = "${var.asg.launch_template.name}_${var.name}_${var.environment}"
      DevOps  = var.devops_name
      Project = var.project_name
    }
  }

}

resource "aws_autoscaling_group" "asg-instances" {
  name                  = "${var.asg.autoscaling_group.name}_${var.name}_${var.environment}"
  desired_capacity      = var.asg.autoscaling_group.desired_capacity
  max_size              = var.asg.autoscaling_group.max_size
  min_size              = var.asg.autoscaling_group.min_size
  vpc_zone_identifier   = local.subnets_list
  protect_from_scale_in = var.asg.autoscaling_group.protected_from_scale_in
  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.template-instance.id
      }

    }
  }
  tags = [
    {
      Name    = "${var.asg.autoscaling_group.name}_${var.name}_${var.environment}"
      DevOps  = var.devops_name
      Project = var.project_name
    },
  ]

}

resource "aws_autoscaling_attachment" "asg-attachment" {
  autoscaling_group_name = aws_autoscaling_group.asg-instances.id
  lb_target_group_arn    = aws_lb_target_group.app-lb-tg.arn
}
