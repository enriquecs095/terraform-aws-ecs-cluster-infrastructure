resource "aws_ecs_cluster" "timeoff-cluster" {
  name = "${var.ecs.cluster_name}_${var.environment}"
  tags = {
    Name    = "${var.ecs.cluster_name}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_ecs_task_definition" "tasks" {
  family = "${var.ecs.task_definition.family}_${var.environment}"
  container_definitions = jsonencode([
    {
      name      = "${var.ecs.task_definition.container_definitions.name}_${var.environment}"
      image     = var.ecs.task_definition.container_definitions.image
      cpu       = var.ecs.task_definition.container_definitions.cpu
      memory    = var.ecs.task_definition.container_definitions.memory
      essential = var.ecs.task_definition.container_definitions.essential
      portMappings = [
        {
          containerPort = var.ecs.task_definition.container_definitions.portMappings.containerPort
          hostPort      = var.ecs.task_definition.container_definitions.portMappings.hostPort
        }
      ]
    }
  ])

  tags = {
    Name    = "${var.ecs.task_definition.family}_${var.environment}"
    DevOps  = var.devops_name
    Project = var.project_name
  }
}

resource "aws_ecs_service" "worker" {
  name            = "${var.ecs.ecs_service.name}_${var.environment}"
  cluster         = aws_ecs_cluster.timeoff-cluster.id
  task_definition = aws_ecs_task_definition.tasks.arn
  desired_count   = var.ecs.ecs_service.desired_count
}

