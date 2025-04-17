**1. app/main.py**
```python
from flask import Flask, jsonify, request
from datetime import datetime
import socket

app = Flask(__name__)

@app.route('/')
def home():
    ip = request.remote_addr
    return jsonify({
        "timestamp": datetime.utcnow().strftime('%Y-%m-%d %H:%M:%S UTC'),
        "ip": ip
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
```

**2. app/requirements.txt**
```
flask
```

**3. app/Dockerfile**
```Dockerfile
FROM python:3.9-slim

# Create non-root user
RUN useradd -m appuser

WORKDIR /home/appuser/app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appuser . .
USER appuser

EXPOSE 80
CMD ["python", "main.py"]
```

**4. terraform/provider.tf**
```hcl
provider "aws" {
  region = var.aws_region
}
```

**5. terraform/variables.tf**
```hcl
variable "aws_region" {
  default = "us-east-1"
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
  default = "<your-dockerhub-username>/simpletimeservice:latest"
}
```

**6. terraform/main.tf**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "4.0.2"

  name = "simpletimeservice-vpc"
  cidr = var.vpc_cidr

  azs             = ["us-east-1a", "us-east-1b"]
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_dns_hostnames = true
  enable_dns_support   = true
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = var.cluster_name
  cluster_version = "1.27"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  manage_aws_auth = true
  enable_irsa     = true

  node_groups = {
    simpletimeservice_nodes = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.small"]
    }
  }
}
```

**7. terraform/outputs.tf**
```hcl
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "kubeconfig" {
  value = module.eks.kubeconfig
  sensitive = true
}
```

**8. terraform/terraform.tfvars**
```hcl
aws_region = "us-east-1"
```

**9. README.md**
```markdown
# SimpleTimeService with AWS EKS Deployment

## Purpose
A minimalist Python Flask web service returning a timestamp and client IP address. Deployed on AWS EKS using Terraform.

## Features
- Returns current UTC timestamp and requester's IP
- Dockerized with non-root user
- AWS EKS deployment using Terraform

## Project Structure
```
.
├── app
│   ├── main.py
│   ├── requirements.txt
│   └── Dockerfile
├── terraform
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars
│   └── provider.tf
└── README.md
```

## Prerequisites
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [Docker](https://www.docker.com/products/docker-desktop/)
- AWS account with appropriate IAM permissions

## Steps

### 1. Build & Push Docker Image
```bash
cd app
docker build -t <your-dockerhub-username>/simpletimeservice:latest .
docker push <your-dockerhub-username>/simpletimeservice:latest
```

### 2. Deploy Infrastructure with Terraform
```bash
cd terraform
terraform init
terraform apply -auto-approve
```

### 3. Configure kubectl
```bash
aws eks --region us-east-1 update-kubeconfig --name simpletimeservice-eks
```

### 4. Deploy App to EKS
```bash
kubectl apply -f https://raw.githubusercontent.com/<your-username>/<repo-name>/main/k8s/simpletimeservice-deployment.yaml
```

### 5. Access the Application
Use the external LoadBalancer URL:
```bash
kubectl get svc -n default
```
Visit the external IP to see the JSON response:
```json
{
  "timestamp": "2025-04-17 08:35:57 UTC",
  "ip": "<your-public-ip>"
}
```

## Notes
- Ensure AWS credentials are configured via `aws configure` or environment variables.
- Do NOT commit secrets to GitHub.
- This setup uses public Terraform modules for VPC and EKS.
```

**10. Kubernetes Manifests (optional if included)**
You can include a simple `k8s/simpletimeservice-deployment.yaml`:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: simpletimeservice
spec:
  replicas: 1
  selector:
    matchLabels:
      app: simpletimeservice
  template:
    metadata:
      labels:
        app: simpletimeservice
    spec:
      containers:
      - name: simpletimeservice
        image: <your-dockerhub-username>/simpletimeservice:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: simpletimeservice
spec:
  type: LoadBalancer
  selector:
    app: simpletimeservice
  ports:
    - port: 80
      targetPort: 80
```
Replace `<your-dockerhub-username>` and `<your-username>/<repo-name>` with actual values before committing to GitHub.
