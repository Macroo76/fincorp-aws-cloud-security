# FinCorp — Task 5: Secure EC2

## Objective

Secure the FinCorp EC2 application servers by removing unnecessary SSH exposure and implementing AWS Systems Manager Session Manager for administrative access.

The target architecture was:

**Administrator ? AWS Systems Manager Session Manager ? Private EC2**

The application servers should remain in private subnets without requiring public IP addresses, inbound Internet SSH, or a bastion host for normal administration.

---

## 1. Initial Security Finding — Broad SSH Access

### Finding

The application security group initially permitted SSH access to the application instances.

The original design allowed TCP/22 access through the bastion security group:

```text
Bastion SG ? TCP/22 ? Application SG
```

The bastion itself initially permitted SSH from:

```text
0.0.0.0/0
```

### Risk

SSH-based administration introduces additional attack surface and requires management of:

* SSH keys
* Bastion infrastructure
* SSH access rules
* Bastion operating-system security
* Bastion patching and monitoring

Although the application instances were located in private subnets and were not directly Internet-accessible, maintaining SSH access was unnecessary for the desired architecture.

### Evidence

The application security group contained a temporary SSH rule:

```text
TCP/22 ? Bastion Security Group
```

The bastion security group allowed:

```text
TCP/22 ? 0.0.0.0/0
```

---

# 2. Security Architecture

The EC2 instances were redesigned to use AWS Systems Manager Session Manager.

Final architecture:

```text
                         AWS
                          ¦
                 Session Manager
                          ¦
                          ?
                +------------------+
                ¦  Private EC2 #1  ¦
                ¦  Private EC2 #2  ¦
                +------------------+
                         ¦
             +-----------+------------+
             ¦           ¦            ¦
             ?           ?            ?
           SSM       SSMMessages      S3
        Interface     Interface      Gateway
        Endpoint      Endpoint      Endpoint
```

This allows administrative access without exposing SSH to the network.

---

# 3. SSM Interface VPC Endpoints

Two Interface VPC Endpoints were configured:

```text
com.amazonaws.eu-west-1.ssm
com.amazonaws.eu-west-1.ssmmessages
```

Both endpoints:

* Are deployed in the private application subnets
* Use private DNS
* Use a dedicated VPC Endpoint security group
* Allow HTTPS/TCP 443 from the application security group

Security relationship:

```text
Application SG
      ¦
      ¦ TCP/443
      ?
VPCE SG
      ¦
      +-- SSM
      +-- SSMMessages
```

This allows the private EC2 instances to communicate with Systems Manager without requiring Internet connectivity.

---

# 4. S3 Gateway VPC Endpoint

During implementation, automatic SSM Agent installation initially failed.

The EC2 instances were able to reach the SSM interface endpoints, but the Amazon Linux package repositories could not be reached.

The cloud-init logs showed repository connection timeouts while attempting to download Amazon Linux package metadata.

### Root Cause

The Amazon Linux repositories used by the instance were backed by Amazon S3.

The private EC2 instances had no NAT Gateway or other Internet path, and the SSM Interface Endpoints do not provide general S3 connectivity.

Therefore:

```text
Private EC2
    ¦
    +-- dnf install amazon-ssm-agent
                 ¦
                 ?
          Amazon Linux repo
                 ¦
                 X
            No S3 route
```

### Remediation

An Amazon S3 **Gateway VPC Endpoint** was added and associated with the private application route table.

```text
Private EC2
    ¦
    ?
Private Route Table
    ¦
    ?
S3 Gateway Endpoint
    ¦
    ?
Amazon S3
```

This allowed the private instances to access the S3-backed Amazon Linux repositories without requiring a NAT Gateway.

---

# 5. Security Group Design

A dedicated security group was created for the Interface VPC Endpoints.

The application security group allows HTTPS traffic to the endpoint security group:

```text
Application SG
      ¦
      ¦ TCP/443
      ?
VPCE SG
```

The endpoint security group allows HTTPS traffic from the application security group.

The application security group therefore does not require unrestricted outbound Internet access for SSM communication.

The S3 Gateway Endpoint is handled through the VPC route table rather than an Interface Endpoint security group.

---

# 6. EC2 Configuration

The EC2 instances use an IAM instance profile containing the required Systems Manager permissions.

The EC2 Terraform resource was also configured with dependencies on the VPC endpoints:

```hcl
depends_on = [
  aws_vpc_endpoint.s3,
  aws_vpc_endpoint.ssm,
  aws_vpc_endpoint.ssmmessages
]
```

This ensures Terraform creates the required endpoint infrastructure before creating the application instances.

The EC2 `user_data` installs and starts the SSM Agent automatically.

This was important because manually installing the agent would not demonstrate a reproducible infrastructure deployment.

---

# 7. Validation

After the S3 Gateway Endpoint was added, the EC2 instances were recreated.

The following was successfully demonstrated:

### Automatic SSM Agent installation

The SSM Agent was installed automatically through the EC2 bootstrap process.

### Automatic registration

The instances successfully registered with AWS Systems Manager.

Expected state:

```text
Instance ID       Ping
-----------------------
EC2 Instance #1   Online
EC2 Instance #2   Online
```

### Session Manager connectivity

A Session Manager session was successfully established to the private EC2 instance.

This demonstrated that administrative access was possible without SSH.

---

# 8. Final Security State

The temporary SSH access was removed after Session Manager was successfully validated.

The application security group no longer requires inbound TCP/22 for administration.

Final application security group architecture:

### Inbound

```text
ALB SG ? TCP/80 ? Application SG
```

No administrative SSH access is required.

### Outbound

```text
Application EC2
     ¦
     +-- TCP/443 ? SSM/SSMMessages Interface Endpoints
     ¦
     +-- S3 ? S3 Gateway Endpoint
```

---

# 9. Security Improvements

The remediation provides several security improvements:

* Removed unnecessary SSH administration
* Removed dependency on a bastion host for EC2 management
* Eliminated the need for public EC2 access
* Kept application instances in private subnets
* Used private AWS service connectivity
* Used S3 Gateway Endpoint instead of NAT solely for package repository access
* Restricted Interface Endpoint access using security groups
* Automated SSM Agent installation through Terraform/user data
* Enabled reproducible EC2 provisioning
* Validated administrative access through Session Manager

---

# 10. Final Architecture

```text
                         Administrator
                              ¦
                              ¦
                              ?
                    AWS Systems Manager
                    Session Manager
                              ¦
                              ?
                    +-----------------+
                    ¦   Private EC2   ¦
                    ¦                 ¦
                    ¦ Application     ¦
                    +-----------------+
                             ¦
                +------------+-------------+
                ¦            ¦             ¦
                ?            ?             ?
             SSM VPCE   SSMMessages VPCE  S3 VPCE
             Interface    Interface       Gateway
                ¦            ¦             ¦
                +--------------------------+
                             ¦
                         AWS Services
```

---

# 11. Final Result

**Task 5 — Secure EC2: Completed**

The FinCorp EC2 instances are now administered through AWS Systems Manager Session Manager while remaining in private subnets.

The final implementation removes the need for inbound SSH administration and provides private connectivity to the AWS services required by the application instances.
