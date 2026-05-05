# Secure HA Web Stack Prototype (Project 2)

This repository contains a **Prototype** implementation of a High-Availability (HA), 3-tier web architecture on AWS. It is designed to demonstrate modern CloudOps principles, including infrastructure-as-code (IaC), least-privilege security, and automated code deployment.

## 🏗️ Architecture Overview
The stack is deployed across **3 Availability Zones** in the `us-east-1` region to ensure maximum uptime and fault tolerance.

### 🌐 Networking & Connectivity
*   **VPC:** Custom `10.0.0.0/16` network with a structured 9-subnet layout:
    *   **3 Public Subnets:** For the Application Load Balancer and NAT Gateway ingress.
    *   **3 Private Subnets:** Hosting the EC2 Application Tier (no direct internet ingress).
    *   **3 Isolated Subnets:** Dedicated to the RDS Database Tier.
*   **NAT Gateway:** High-speed internet egress for private instances to fetch updates and dependencies.
*   **VPC Endpoints (PrivateLink):** 
    *   **S3 Gateway Endpoint:** Secure, cost-free access to S3 without traversing the public internet.
    *   **SSM Interface Endpoints:** (`ssm`, `ssmmessages`, `ec2messages`) Enables secure, agent-based management via AWS Systems Manager without Bastion hosts.

### 💻 Compute Tier
*   **Auto Scaling Group (ASG):** Automatically maintains desired instance count and replaces unhealthy nodes.
*   **Launch Template:** Enforces **IMDSv2** (required) and utilizes a custom User Data script for automated bootstrapping.
*   **Load Balancing:** An Application Load Balancer (ALB) handles SSL termination (simulated) and distributes traffic to the ASG across all AZs.

### 🗄️ Database Tier
*   **Multi-AZ RDS (MySQL):** A fully managed database with synchronous replication to a standby instance in a different AZ for automatic failover.
*   **Secrets Management:** DB credentials and connection strings are stored in **AWS Secrets Manager** and fetched dynamically by the application, eliminating hardcoded secrets.

### 🔐 Security & IAM
*   **Defense in Depth:** Layered Security Groups ensure that the Database tier only accepts traffic from the App tier, and the App tier only from the ALB.
*   **Least Privilege IAM:** The EC2 Instance Profile is restricted to specific `s3:GetObject` and `secretsmanager:GetSecretValue` permissions.

## 🚀 Deployment Workflow
The infrastructure is managed using **OpenTofu** (v1.6+).

1.  **IaC Initialization:** The network, IAM roles, and RDS instances are defined in `.tf` files.
2.  **S3-Backed Deployment:** The `app.py` script is uploaded to a private S3 bucket.
3.  **Bootstrapping:** EC2 instances use `User Data` scripts to:
    *   Install dependencies (`Flask`, `Gunicorn`, `Boto3`, `PyMySQL`).
    *   Pull the latest `app.py` from S3 via the VPC Endpoint.
    *   Start the API service via Gunicorn.

## 🛠️ Tech Stack
*   **IaC:** OpenTofu
*   **Cloud:** AWS (VPC, EC2, ASG, ALB, RDS, S3, Secrets Manager, VPC Endpoints)
*   **Language:** Python 3.9+
*   **Framework:** Flask / Gunicorn

## ⚠️ Prototype Disclaimer
This project is a **functional prototype** intended for development and educational purposes. Before moving to a production environment, the following enhancements are recommended:
*   **Remote State:** Move the `.tfstate` to an S3 backend with DynamoDB locking.
*   **CI/CD:** Implement a pipeline (GitHub Actions/GitLab CI) for automated testing and deployment.
*   **Process Management:** Wrap the API in a `systemd` service for automatic restarts.
*   **HTTPS:** Implement ACM certificates on the ALB for encrypted transit.

---
**Author:** David Duckett
**License:** MIT
