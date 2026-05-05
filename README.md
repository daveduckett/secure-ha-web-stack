# Secure HA Web Stack Prototype (Project 2)

This repository contains a **Prototype** implementation of a High-Availability (HA), 3-tier web architecture on AWS. It is designed to demonstrate modern CloudOps principles, including infrastructure-as-code (IaC), least-privilege security, and automated code deployment.

## 🏗️ Architecture Overview
The stack is deployed across **3 Availability Zones** in the `us-east-1` region to ensure maximum uptime and fault tolerance.

*   **VPC:** Custom 10.0.0.0/16 network with Public, Private, and Isolated subnets across 3 AZs.
*   **Compute:** Auto Scaling Group (ASG) of EC2 instances running a Python/Flask API.
*   **Load Balancing:** Application Load Balancer (ALB) handles ingress traffic and performs health checks.
*   **Database:** Multi-AZ RDS (MySQL) instance located in isolated subnets.
*   **Security:**
    *   **IMDSv2:** Enforced on all EC2 instances for secure metadata access.
    *   **Secrets Management:** DB credentials are dynamically fetched from AWS Secrets Manager at runtime.
    *   **IAM:** Granular, least-privilege roles for EC2-to-S3 and EC2-to-Secrets access.

## 🚀 Deployment Workflow
The infrastructure is managed using **OpenTofu** (v1.6+).

1.  **IaC Initialization:** The network, IAM roles, and RDS instances are defined in `.tf` files.
2.  **S3-Backed Deployment:** The `app.py` script is uploaded to a private S3 bucket.
3.  **Bootstrapping:** EC2 instances use `User Data` scripts to:
    *   Install dependencies (Flask, Gunicorn, Boto3).
    *   Pull the latest `app.py` from S3.
    *   Start the API service via Gunicorn.

## 🛠️ Tech Stack
*   **IaC:** OpenTofu
*   **Cloud:** AWS (EC2, ASG, ALB, RDS, S3, Secrets Manager)
*   **Language:** Python 3.9+
*   **Framework:** Flask / Gunicorn

## ⚠️ Prototype Disclaimer
This project is a **functional prototype** intended for development and educational purposes. Before moving to a production environment, the following enhancements are recommended:
*   **Remote State:** Move the `.tfstate` to an S3 backend with DynamoDB locking.
*   **CI/CD:** Implement a pipeline (GitHub Actions/GitLab CI) for automated testing and deployment.
*   **Process Management:** Wrap the API in a `systemd` service for automatic restarts.
*   **Network Hardening:** Replace NAT Gateway with VPC Endpoints for S3 and Secrets Manager to keep traffic internal.

---
**Author:** David Duckett
**License:** MIT
