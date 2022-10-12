# AWS VPC Terraform module
AWS Terraform modules create VPC resources on AWS and run an Apache web server.
This project was created with Terraform 1.3 and is based on the ECS cluster and autoscaling group EC2 with the specified arguments.

# Usage

## ECS CLUSTER infrastructure

![](ecs.png)

### Module

```hcl
module "ecs-cluster-infrastructure" {
  source      = "enriquecs095/ecs-cluster-infrastructure/aws"
  version     = "4.34.0"
  name        = "ecs"
  environment = "environment_name"
  providers = {
    aws = aws.main_region
  }

  vpc = {
    cidr_block   = "10.2.0.0/16"
    dns_support  = true
    dns_hostname = true
  }
  subnets = [
    {
      name              = "subnet_1"
      availability_zone = "us-east-1a"
      cidr_block        = "10.2.1.0/24"
    },
    {
      name              = "subnet_2"
      availability_zone = "us-east-1b"
      cidr_block        = "10.2.2.0/24"
    }
  ]
  security_groups = [
    {
      name        = "sg_load_balancer_1"
      description = "Security group for load balancer"
      list_of_rules = [
        {
          name        = "ingress_rule_1"
          description = "Allow inbound trafic from anywhere"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          cidr_blocks = ["0.0.0.0/0"]
          type        = "ingress"
        },
        {
          name        = "egress_rule_3"
          description = "Allow outbound trafic to anywhere"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          cidr_blocks = ["0.0.0.0/0"]
          type        = "egress"
        }
      ]
    },
    {
      name        = "sg_asg_1"
      description = "Security group for instances"
      list_of_rules = [
        {
          name        = "ingress_rule_2"
          description = "Allow inbound trafic from anywhere"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          cidr_blocks = ["0.0.0.0/0"]
          type        = "ingress"
        },
        {
          name        = "egress_rule_4"
          description = "Allow outbound trafic to anywhere"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          cidr_blocks = ["0.0.0.0/0"]
          type        = "egress"
        }
      ]
    },
  ]
  load_balancer = {
    name               = "lb-1"
    internal           = false
    load_balancer_type = "application"
    subnets = [
      "subnet_1",
      "subnet_2"
    ]
    security_groups = [
      "sg_load_balancer_1"
    ]
    lb_target_group = {
      name     = "tg-1"
      port     = "80"
      vpc_id   = "vpc_1"
      protocol = "HTTP"
      health_check = {
        enable   = true
        path     = "/"
        interval = 10
        port     = 80
        protocol = "HTTP"
        matcher  = "200-299"
      }
    }
    lb_listener = [
      {
        name                = "lb_l_1"
        port                = "80"
        protocol            = "HTTP"
        default_action_type = "redirect"
        target_group_arn    = null
        ssl_policy          = null
        certificate_arn     = null
        redirect = [
          {
            status_code = "HTTP_301"
            port        = 443
            protocol    = "HTTPS"
          }
        ]
      },
      {
        name                = "lb_l_2"
        port                = "443"
        protocol            = "HTTPS"
        default_action_type = "forward"
        target_group_arn    = "tg-1"
        ssl_policy          = "ELBSecurityPolicy-2016-08"
        certificate_arn     = "acm_certificate_1"
        redirect            = []
      },

    ]
  }
  asg = {
    launch_template = {
      name            = "launch_template_1"
      instance_type   = "t3.medium"
      key_pair        = "key_pair_name"
      ami_name        = "amzn2-ami-hvm-*-x86_64-gp2"
      security_groups = ["sg_asg_1"]
      user_data       = "command_script_filename.sh"
    }
    autoscaling_group = {
      name                    = "autoscaling_group_1"
      desired_capacity        = 2
      max_size                = 6
      min_size                = 1
      vpc_zone_identifier     = ["subnet_1", "subnet_2"]
      protected_from_scale_in = true
    }
  }
  acm_certificate = {
    name                   = "acm_1"
    dns_name               = "mydnsname.com."
    validation_method      = "DNS"
    route53_record_type    = "A"
    ttl                    = 60
    evaluate_target_health = true
  }

  ecs = {
    cluster_name = "cluster_1"
    task_definition = {
      family = "ecs_1"
      container_definitions = {
        image     = "my_image_on_aws_ecr_or_docker_hub"
        essential = true
        cpu       = 2
        memory    = 512
        name      = "node_app_1"
        portMappings = {
          containerPort = 80
          hostPort      = 80
        }
      }

    }

    ecs_service = {
      name          = "cluster_service_1"
      desired_count = 2
    }
  }

  waf = {
    ip_set = {
      name = "ipset_1"
    }
    waf_rule = {
      name        = "wafrule1"
      metric_name = "wafrule1"
      negated     = false
      type        = "IPMatch"
    }
    waf_acl = {
      name           = "wafacl1"
      metric_name    = "wafacl1"
      default_action = "ALLOW"
      type           = "BLOCK"
      priority       = 1
    }
  }
  devops_name  = "DevOps"
  project_name = "ecs_project"

}
```
### Output file

```hcl
output "alb_dns_name_ecs" {
  description = "The DNS name of the application load balancer"
  value       = module.ecs-cluster-infrastructure.alb_dns_name_ecs
}

output "url_ecs" {
  description = "The url of the dns server for the web application"
  value       =  module.ecs-cluster-infrastructure.url_ecs
}
```
### Configuration file 

```hcl
terraform {
    required_version = ">=0.12.0"
}

provider "aws" {
    region = "us-east-1"
    alias = "main_region"
}
```

If you want to store the terraform.tfstate file remotely on the S3 bucket, replace the previous terraform configuration and paste the following:

```hcl
terraform {
    required_version = ">=0.12.0"
    backend "s3" {
        region= "us-east-1"
    }
}

provider "aws" {
    region = "us-east-1"
    alias = "main_region"
}

```
# Stand up the infrastructure

Follow steps #1, #9, and #10 if you want to create an S3 bucket on AWS to store the terraform state file remotely.

## 1. Create a bucket

Run the following command and change the parameter "bucket-name" for the name of the bucket you want to create:

    aws s3api create-bucket --bucket bucket-name 
 
## 2. Create a public key and store it on AWS 

Run the following command on linux or WSL 2 and change "my-key" name for the specific key pair you want to create:

    ssh-keygen -t rsa -b 2048 -f ~/.ssh/my-key 

This command imports the provided public key to a single region: **

    aws ec2 import-key-pair --key-name "key_pair_name" --public-key-material fileb://~/.ssh/key_pair_name.pub --region region-name 

## 3. Create a file that execute the commands to install apache

Create a file "my_file.sh" for the "user_data" argument then copy and paste the following commands:

    #! /bin/bash
    sudo yum update -y
    sudo yum install -y httpd.x86_64
    sudo systemctl start httpd.service
    sudo systemctl enable httpd.service

## 4. Terraform init

Run the following command in the project directory and change the parameters values:

    terraform init -backend-config="bucket=my_bucket_name" -backend-config="key=environment_name/filename" 

### Optionally If you don't want to store the terraform state file on AWS S3 bucket, run the following command:

    terraform init

## 5. Terraform plan

After run the previous command, run the following command:

    terraform plan 

## 6. Terraform apply 

Finally run the command below:

    terraform apply

    and then write "yes" to confirm the action

### If you want to runs it automatically:

    terraform apply -auto-approve

## 7. Terraform destroy

The following command will destroy the resources:

    terraform destroy

    and then write "yes" to confirm the action

### If you want to runs it automatically:

    terraform destroy -auto-approve

## 8. Removing the working directory

Run the following command for deleting the ".terraform" directory and ".terraform.lock.hcl" file:

    rm -r .terraform/ .terraform.lock.hcl

## 9.Emptying the bucket

The following rm command removes objects that have the key name prefix doc, for example, doc/doc1 and doc/doc2:

    aws s3 rm s3://bucket-name/doc --recursive 

Use the following command to remove all objects without specifying a prefix:

    aws s3 rm s3://bucket-name --recursive 

## 10. Deleting the bucket

Run the following command and change the parameter "bucket_name" for the name of the bucket you want to delete:

    aws s3api delete-bucket --bucket bucket-name 

## 11. Deleting the key pairs

Run the following command and change the parameter values:**

    aws ec2 delete-key-pair --key-name "my-key" --region region-name 

** If you need to store/delete the key pair in more than one region, change the "region-name" and run the previous command as needed. In this case we will need to execute the command on the regions "us-east-1" and "us-west-2".

## Documentation

- [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/configuration)
- [Creating AWS Bucket Resource](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)
- [Emptying AWS Bucket Resource](https://docs.aws.amazon.com/AmazonS3/latest/userguide/empty-bucket.html)
- [Deleting AWS Bucket Resource](https://docs.aws.amazon.com/AmazonS3/latest/userguide/delete-bucket.html)
- [Import key pairs on AWS CLI](https://docs.aws.amazon.com/cli/latest/reference/ec2/import-key-pair.html)
- [Deleting key pairs on AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-keypairs.html)