# FinCorp Cloud Infrastructure  Project Journal

This document records the development process, decisions,
problems, troubleshooting and lessons learned throughout
the FinCorp AWS infrastructure project.

---

## Project Status

Status: In Progress

---

## Tasks

# FinCorp Cloud Infrastructure  Project Journal

## Project Background

FinCorp is an electronic commerce company with a website used by customers across North Africa, including Libya, to purchase products online.

The company has three main departments:

* **Development**
* **Operations**
* **Finance**
* **Security**

The existing AWS environment contains the following employees:

### Development

* Alice
* Bob
* Charlie
* David

### Finance

* Emma
* Frank

### Operations

* George
* Henry
* Irene

### Security

* Max

FinCorp already had an existing AWS infrastructure, and I was assigned to perform a security audit of the environment and identify potential security risks and violations of the **least-privilege principle**.

---

# Task 1 � Existing Infrastructure Security Audit

## Objective

The objective of Task 1 was to review the existing AWS IAM configuration and identify security vulnerabilities, excessive permissions, inappropriate access, and other security weaknesses.

The audit focused primarily on:

* IAM users
* IAM groups
* IAM policies
* Direct policy attachments
* Access keys
* MFA configuration
* Excessive permissions
* Violations of least privilege

---

## Audit Process

I first enumerated the IAM users in the AWS account.

### List IAM users

```bash
aws iam list-users
```

I then reviewed the IAM groups in the environment to understand how users were organized and which permissions were inherited through group membership.

For individual users, I used:

```bash
aws iam get-user --user-name <username>
```

This allowed me to review user information, including metadata such as tags.

I then reviewed the policies attached to each IAM group using:

```bash
aws iam list-attached-group-policies --group-name <group-name>
```

After identifying the attached policies, I reviewed the policy documents to determine what permissions each department and individual user actually had.

I also checked for policies attached directly to individual users rather than inherited through groups.

This identified several direct policy attachments that represented significant security risks.

Finally, I reviewed the users' access-key configuration and found long-lived access keys, which represented an additional security concern.

---

# Security Findings

## Finding 1  Alice Has Excessive Administrative Privileges

### User

Alice >> Development

### Evidence

Policy:

```text
fincorp-lab-dev-alice-admin
```

### Finding

Alice had full administrative access to AWS resources.

This violates the principle of least privilege because a developer should not automatically have unrestricted administrative access to the entire AWS environment.

### Risk

If Alice's credentials were compromised, an attacker could potentially access, modify, or delete a large portion of the company's AWS infrastructure.

### Recommendation

Remove the unrestricted administrative permissions and replace them with a developer-specific policy containing only the permissions required for Alice's responsibilities.

---

## Finding 2  Bob Has Full S3 Access

### User

Bob >> Development

### Evidence

Policy:

```text
fincore-lab-dev-bob-direct
```

### Finding

Bob has broad/full access to Amazon S3.

### Risk

Excessive S3 permissions could allow accidental or unauthorized access to sensitive company data, including the possibility of modifying or deleting S3 objects or accessing buckets belonging to other departments.

### Recommendation

The policy should be restricted according to Bob's actual responsibilities.

Bob should receive only the S3 permissions and resources required for his work rather than unrestricted access to the company's S3 environment.

---

## Finding 3  Development Group Has EC2 Start/Stop Permissions

### Users affected

* Alice
* Bob
* Charlie
* David

### Evidence

The permissions are inherited through the Development group policy.

### Finding

The Development group has permissions to start and stop EC2 instances.

The group also contains Alice and Bob, meaning these permissions are inherited by all members of the group.

### Risk

Developers should not automatically have the ability to start and stop all EC2 instances in the company's AWS account.

This creates unnecessary operational access and violates separation of responsibilities.

### Recommendation

Remove EC2 start/stop permissions from the Development group.

These permissions should be restricted to the Operations team where operational responsibility belongs.

---

## Finding 4  Operations Policy Allows EC2 Actions Across the Account

### Users affected

* George
* Henry
* Irene

### Evidence

Policy:

```text
fincore-lab-operations-policy
```

### Finding

The Operations policy allows users to:

* List EC2 instances
* Start EC2 instances
* Stop EC2 instances
* Change EC2 instance names

The permissions apply broadly across EC2 resources in the account.

### Risk

A compromised Operations user's credentials could be used to perform potentially disruptive actions against EC2 infrastructure across the AWS account.

### Recommendation

The permissions should be restricted to the EC2 resources that the Operations team actually needs to manage.

In addition, MFA should be required before performing sensitive operational actions such as starting and stopping EC2 instances.

---

## Finding 5  Finance User Emma Can Discover S3 Resources Outside Her Scope

### User

Emma >> Finance

### Evidence

Policy:

```text
fincore-lab-finance-policy
```

### Finding

Emma's Finance policy allows her to list S3 resources beyond the S3 resources that she is expected to manage.

She can discover S3 buckets outside her intended scope.

### Risk

This provides unnecessary visibility into company resources that are unrelated to Emma's responsibilities.

Even when a user cannot modify a resource, unnecessary resource discovery can provide useful information to an attacker if the user's credentials are compromised.

### Recommendation

Restrict S3 listing and access to the resources required by the Finance department and remove unnecessary access to unrelated buckets.

---

## Finding 6  Frank Has Excessive EC2 Permissions

### User

Frank >> Finance

### Evidence

Directly attached policy:

```text
fincore-lab-fin-frank-ec2
```

### Finding

Frank has an additional directly attached policy that provides the ability to stop and terminate EC2 instances across the account.

### Risk

A Finance user should not normally have the ability to stop or terminate infrastructure across the AWS environment.

The ability to terminate EC2 instances could cause significant operational disruption.

### Recommendation

Remove the EC2 policy from Frank and ensure that his permissions are limited to the Finance responsibilities he actually needs.

---

# Finding 7  MFA Is Not Configured

### Finding

During the audit, I found that MFA was not applied to the IAM users.

### Risk

If a user's password or credentials are compromised, an attacker may be able to authenticate without an additional authentication factor.

This is particularly important for users with privileged or operational permissions.

### Recommendation

Require MFA for human IAM users, with stronger controls for privileged and sensitive operations.

---

# Finding 8 � Long-Lived Access Keys

### Finding

During the IAM audit, I also identified long-lived access keys associated with IAM users.

### Risk

Long-lived credentials increase the risk associated with credential leakage.

If an access key is exposed through a workstation, source code, configuration file, or another location, it may remain usable until it is disabled or deleted.

### Recommendation

Review all access keys and remove unnecessary long-lived credentials.

Where programmatic access is required, use appropriate temporary credentials and IAM roles where possible.

---

# Directly Attached Policies

During the audit, I specifically checked for policies attached directly to IAM users.

This was important because direct user policy attachments can make access management more difficult and can bypass the consistent permission model provided by groups.

I identified **three direct policy attachments** that represented critical security findings.

These included excessive permissions assigned directly to individual users.

---

# Evidence Collected

Screenshots were captured during the audit to document the existing environment and support the identified findings.

Evidence includes:

* IAM users
* IAM groups
* Group policies
* Individual user details
* Directly attached policies
* IAM policy permissions
* Access-key configuration
* MFA configuration

Screenshots are stored in:

```text
screenshots/task-01/
```

---

# Overall Task 1 Assessment

The initial IAM audit identified several security weaknesses related to excessive permissions, insufficient separation of responsibilities, lack of MFA, direct user policy attachments, overly broad resource access, and long-lived access keys.

The main security principle affected was **least privilege**.

The next stage of the project will be to remediate the identified IAM issues while preserving the permissions required for each department to perform its responsibilities.

---

# Lessons Learned

This task demonstrated the importance of reviewing IAM access from multiple perspectives rather than looking only at individual policies.

A user's effective permissions can come from:

* Directly attached policies
* Group membership
* Multiple policies
* Resource-level permissions
* IAM roles
* Other AWS access mechanisms

Therefore, an IAM security audit should examine the complete permission path rather than reviewing only individual users.

I also learned that excessive permissions can exist even when a user does not have an explicitly administrative policy. Permissions inherited through groups can still provide access beyond what the user's role requires.

## Development Log