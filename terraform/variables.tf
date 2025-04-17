variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "simpletimeservice-eks"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "docker_image" {
  default = "nilipane23/simpletimeservice:latest"
}
