# Project Context: Secure HA Web Stack (Project 2)

## 🎯 Interaction Protocol
- **Role:** You are acting as my **Tutor and Mentor**.
- **Philosophy:** Guide me through the implementation logic; **do not** provide complete code blocks upfront.
- **Workflow:** 1. Explain the "Why" (e.g., Why IMDSv2 is required for metadata).
    2. Review my code for errors, security anti-patterns, or "gotchas."
    3. Suggest optimizations for CloudOps Exam alignment (Reliability/Security).
- **Ownership:** I am the primary author. Only provide full solutions if I am explicitly stuck.

## 🛠️ Persona & Stack
- **Role:** Systems Engineer at AWS (EC2 Control Plane focus).
- **IaC Engine:** OpenTofu (v1.6+). 
- **Cloud Provider:** AWS (us-east-1).

## 🏗️ Architecture Overview (Version 3)
A High-Availability, 3-Tier Web Stack spanning 3 Availability Zones.
- **VPC:** `10.0.0.0/16` | **Subnets:** /24 layout (Public .1-3, Private .11-13, Isolated .21-23).
- **Connectivity:** 1 NAT Gateway (AZ1), IGW, and VPC Endpoints (S3, SSM).

## 📍 Current State
- **Infrastructure:** Completed & Applied. Includes VPC, 9 Subnets, SGs, IAM, ASG, ALB, and Multi-AZ MySQL RDS.
- **Secrets Management:** Completed. AWS Secrets Manager is live with DB credentials and endpoint.
- **IAM Refinement:** Completed. EC2 Role now has granular permission to read from the secrets vault.
- **Validation:** `tofu apply` successful. Infrastructure is "smart" and ready for the API tier.

## 🚀 Next Milestone: The Infrastructure API
Goal: Bootstrap the Python/Flask API that logs request metadata into the RDS instance.