terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.83.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = "AKIAZ3MGNADJJH6YHU"
  secret_key = "lzu35aP3QamVI9BMt6o44tAbeewGCem4V"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "simpletimeservice-vpc"
  cidr = var.vpc_cidr

  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    Terraform = "true"
    Project   = "SimpleTimeService"
  }
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "20.35.0"
  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnet_ids      = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  enable_irsa = true

  eks_managed_node_group_defaults = {
    instance_types = ["t3.medium"]
  }

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      min_capacity     = 1
      max_capacity     = 3
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

resource "kubernetes_deployment" "simpletimeservice" {
  metadata {
    name      = "simpletimeservice"
    namespace = "default"
    labels = {
      app = "simpletimeservice"
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "simpletimeservice"
      }
    }

    template {
      metadata {
        labels = {
          app = "simpletimeservice"
        }
      }

      spec {
        container {
          name  = "simpletimeservice"
          image = var.container_image

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "simpletimeservice" {
  metadata {
    name      = "simpletimeservice"
    namespace = "default"
  }

  spec {
    selector = {
      app = "simpletimeservice"
    }

    port {
      port        = 80
      target_port = 8080
    }

    type = "LoadBalancer"
  }
}
