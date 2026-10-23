# FinCorp — AWS Cloud Security & Terraform Portfolio

## Overview

FinCorp is a hands-on AWS cloud infrastructure and security engineering project built with Terraform. It models a fictional financial e-commerce environment and demonstrates infrastructure as code, network segmentation, identity and access management, centralized auditing, and secure operations.

The project is designed to demonstrate practical skills relevant to **Cloud Security Engineer, AWS Cloud Engineer, and DevSecOps** roles.

## Objectives

- Deploy repeatable AWS infrastructure using Terraform.
- Separate public-facing infrastructure from private application and database resources.
- Implement IAM least-privilege access and permissions boundaries.
- Centralize AWS API activity logging with CloudTrail and Amazon S3.
- Apply security controls to network traffic, storage, and administrative access.
- Practice validating permissions, investigating audit events, and managing infrastructure changes safely.

## Architecture

The environment is designed around an Amazon VPC with public and private network tiers.

- **Ingress:** An Application Load Balancer (ALB) provides the application entry point.
- **Compute:** Two application EC2 instances support the application tier.
- **Database:** Amazon RDS for PostgreSQL provides the database tier.
- **Outbound connectivity:** Two NAT gateways support outbound access from private subnets.
- **Administration:** A bastion host is included in the infrastructure configuration.
- **Management:** AWS Systems Manager (SSM) is configured for supported instance-management workflows.
- **Audit logging:** AWS CloudTrail records API activity, with logs stored in an S3 bucket configured with security controls.
- **Identity and access:** IAM policies, roles, trust policies, and developer permissions boundaries support access-control exercises.

See the architecture diagram in `docs/architecture.md`.

## Technology Stack

| Category | Technologies |
|---|---|
| Infrastructure as Code | Terraform |
| Cloud platform | Amazon Web Services (AWS) |
| Networking | VPC, public/private subnets, routing, NAT gateways |
| Application access | Application Load Balancer, EC2 |
| Database | Amazon RDS for PostgreSQL |
| Identity and access | AWS IAM, policies, roles, permissions boundaries |
| Audit and logging | AWS CloudTrail, Amazon S3 |
| Instance management | AWS Systems Manager |
| Automation and validation | AWS CLI, Terraform, PowerShell, JSON policy documents |

## Security Controls and Learning Areas

### 1. Network segmentation

The infrastructure separates public-facing resources from private application and database resources. Security groups and routing should restrict traffic to the minimum required for each tier.

### 2. IAM least privilege

The project contains separate IAM policy documents for development, finance, operations, role assumption, and security-audit access.

The goal is to demonstrate how access can be scoped by role and responsibility instead of granting broad permissions to every user.

### 3. Permissions boundaries

A developer permissions boundary is included to constrain the maximum permissions available to developer identities. A permissions boundary does not independently grant permissions; effective access still depends on the applicable identity policies and other authorization controls.

### 4. CloudTrail auditing

CloudTrail captures AWS API activity for security monitoring and investigation. The configured S3 logging destination provides a place to retain and inspect trail data.

### 5. Secure infrastructure management

The project includes an SSM-related EC2 instance role/profile and supports exploring administrative access without relying exclusively on direct inbound SSH access.

### 6. Terraform change management

Terraform plans are used to review proposed changes before applying them. State files, credentials, and environment-specific configuration should remain outside version control.

## Repository Structure

```text
.
├── Policies/
│   ├── dev.json
│   ├── dev_bob_direct.json
│   ├── developer_assume_role.json
│   ├── developer_boundary.json
│   ├── finance.json
│   ├── finance_assume_role.json
│   ├── multi-account-trust-policy.json
│   ├── operations.json
│   ├── operations_assume_role.json
│   └── sec-max-cloudtrail-read-only.json
├── docs/
│   └── architecture.md
├── alb.tf
├── cloudtrail.tf
├── compute.tf
├── database.tf
├── iam.tf
├── main.tf
├── network.tf
├── outputs.tf
├── s3.tf
├── security.tf
├── variables.tf
├── versions.tf
├── .terraform.lock.hcl
└── README.md
```

## Prerequisites

Before deploying the infrastructure, prepare:

- An AWS account with authorization to create the required resources.
- AWS CLI installed and configured with an appropriate named profile.
- Terraform installed at a version compatible with the configuration.
- Git for source control.
- Appropriate AWS permissions for the resources being deployed.

Review the configuration and cost implications before running any deployment. Resources such as NAT gateways, EC2 instances, load balancers, and RDS databases may incur charges.

## Deployment Workflow

Run Terraform commands from the directory containing the configuration you intend to deploy.

### 1. Authenticate to AWS

```bash
aws sts get-caller-identity --profile YOUR_PROFILE
```

Verify that the returned account and identity are the intended ones.

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Format and validate

```bash
terraform fmt -recursive
terraform validate
```

### 4. Review the proposed changes

```bash
terraform plan -out=tfplan
```

Inspect the plan carefully for unexpected IAM permissions, public exposure, destructive changes, or resources that may incur costs.

### 5. Apply only after review

```bash
terraform apply tfplan
```

Only apply a plan after confirming the target account, region, resource changes, security posture, and expected costs. Follow the project's actual bootstrap and backend workflow if it requires a separate initialization stage.

## Security Validation Checklist

Use this checklist to document actual test results as the project evolves.

- [ ] Confirm public and private subnet routing is correct.
- [ ] Verify the ALB is the intended application entry point.
- [ ] Confirm application and database security groups restrict unnecessary inbound traffic.
- [ ] Verify that RDS is not unintentionally publicly accessible.
- [ ] Review developer permissions boundaries and effective permissions.
- [ ] Test IAM policies with representative allowed and denied actions.
- [ ] Confirm CloudTrail is recording the intended management events.
- [ ] Verify the S3 log bucket's encryption, public-access blocking, and access policy.
- [ ] Test the intended SSM management workflow.
- [ ] Check for unintended IAM users, access keys, or excessive permissions.
- [ ] Confirm Terraform state and secrets are excluded from Git.
- [ ] Review the final Git-tracked files for sensitive information.

Record the evidence and results of each test rather than marking controls as verified before testing them.

## Cost and Cleanup

This project may create billable AWS resources. Review the AWS Pricing pages for the services used and monitor the account's billing dashboard.

Before destroying resources, inspect the Terraform plan and confirm that it targets only the intended lab resources. Preserve any evidence or state required for your workflow, and do not destroy shared or production resources.

## Limitations and Scope

This is a learning and portfolio environment, not a claim of production certification or a fully audited financial-services platform. Production deployment would require additional review of threat modeling, monitoring and alerting, incident response, resilience, data protection, compliance, and operational procedures.

## Future Improvements

- Add CI checks for Terraform formatting, validation, and static security analysis.
- Add automated IAM policy checks and negative authorization tests.
- Add a threat model and documented security assumptions.
- Add sanitized evidence of CloudTrail investigations and access-control tests.
- Document remote state, state locking, and recovery procedures.
- Add monitoring and alerting for selected security events.
- Add a deployment guide specific to the tested bootstrap and environment workflow.

## Portfolio Focus

This project demonstrates practical work with Terraform, AWS networking, IAM policy design, permissions boundaries, audit logging, and secure infrastructure operations. Its value comes from reproducible configuration, clear documentation, and evidence-backed security testing.

**Author:** Macroo76  
**Repository:** [fincorp-aws-cloud-security](https://github.com/Macroo76/fincorp-aws-cloud-security)
