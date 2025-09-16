resource "aws_ecs_cluster" "main" {
  name = "demo-cluster"
}

resource "aws_launch_template" "ecs" {
  name_prefix   = "ecs-launch-template-"
  image_id     = "ami-000449a00007eadf7"
  instance_type = "t3.micro"
  iam_instance_profile {
    name = var.ec2_instance_profile
  }
  security_group_names = [aws_security_group.ecs.name]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ecs" {
  name                 = "ecs-asg"
  desired_capacity     = 1
  max_size             = 1
  min_size             = 1
  vpc_zone_identifier  = [var.private_app_subnet_id]

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecs-instance"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "ecs" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_task_definition" "nginx_a" {
  family                   = "nginx-a"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "nginx-a"
    image     = "nginx"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 0 }]
    logConfiguration = {
      logDriver = "awslogs"
      options   = {
        awslogs-group         = "/ecs/nginx-a"
        awslogs-region        = var.region
        awslogs-stream-prefix = "nginx"
      }
    }
    entryPoint = ["/bin/sh", "-c"]
    command    = ["echo '<h1>Served by nginx-a</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
  }])
}

resource "aws_ecs_task_definition" "nginx_b" {
  family                   = "nginx-b"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  execution_role_arn       = var.ecs_task_execution_role_arn

  container_definitions = jsonencode([{
    name      = "nginx-b"
    image     = "nginx"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [{ containerPort = 80, hostPort = 0 }]
    logConfiguration = {
      logDriver = "awslogs"
      options   = {
        awslogs-group         = "/ecs/nginx-b"
        awslogs-region        = var.region
        awslogs-stream-prefix = "nginx"
      }
    }
    entryPoint = ["/bin/sh", "-c"]
    command    = ["echo '<h1>Served by nginx-b</h1>' > /usr/share/nginx/html/index.html && nginx -g 'daemon off;'"]
  }])
}

resource "aws_ecs_service" "nginx_a" {
  name            = "nginx-a"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx_a.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.target_group_a_arn
    container_name   = "nginx-a"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_group.ecs]
}

resource "aws_ecs_service" "nginx_b" {
  name            = "nginx-b"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx_b.arn
  desired_count   = 1
  launch_type     = "EC2"

  load_balancer {
    target_group_arn = var.target_group_b_arn
    container_name   = "nginx-b"
    container_port   = 80
  }

  depends_on = [aws_autoscaling_group.ecs]
}

resource "aws_cloudwatch_log_group" "nginx_a" {
  name = "/ecs/nginx-a"
}

resource "aws_cloudwatch_log_group" "nginx_b" {
  name = "/ecs/nginx-b"
}

