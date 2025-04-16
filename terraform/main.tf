provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "simpletimeservice-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  tags = {
    Terraform = "true"
    Project   = "SimpleTimeService"
  }
}

module "ecs" {
  source = "terraform-aws-modules/ecs/aws"

  name               = "simpletimeservice"
  container_insights = true
  capacity_providers = ["FARGATE"]

  vpc_id                         = module.vpc.vpc_id
  subnet_ids                    = module.vpc.private_subnets
  create_task_exec_role         = true
  create_task_role              = true
  fargate_capacity_provider     = true

  ecs_services = {
    simpletimeservice = {
      desired_count = 1
      launch_type   = "FARGATE"

      task_definition = {
        family                   = "simpletimeservice"
        container_definitions = jsonencode([{
          name      = "simpletimeservice"
          image     = var.container_image
          essential = true
          portMappings = [
            {
              containerPort = 8080
              hostPort      = 8080
            }
          ]
        }])
        requires_compatibilities = ["FARGATE"]
        network_mode             = "awsvpc"
        cpu                      = "256"
        memory                   = "512"
      }

      load_balancer = {
        target_group_arn = aws_lb_target_group.this.arn
        container_name   = "simpletimeservice"
        container_port   = 8080
      }
    }
  }
}

resource "aws_lb" "this" {
  name               = "simpletimeservice-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets

  tags = {
    Name = "simpletimeservice-alb"
  }
}

resource "aws_lb_target_group" "this" {
  name     = "simpletimeservice-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  target_type = "ip"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}
