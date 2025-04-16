# SimpleTimeService

A minimalist microservice built with Flask that returns the current timestamp and IP address of the visitor in JSON format.

## 🧱 Technologies Used

- Python + Flask
- Docker
- AWS ECS Fargate
- Terraform
- AWS VPC, ALB

## 📦 Docker

### Build the Docker image

```bash
cd app
docker build -t your-dockerhub-username/simpletimeservice .
