# Task 2  IAM Remediation and Least-Privilege Implementation

## Objective

The objective of Task 2 was to remediate the IAM security findings identified during the initial FinCorp security audit.

The remediation focused on applying the principle of least privilege and ensuring that each department receives only the permissions required to perform its responsibilities.

The main areas addressed were:

* Development permissions
* Operations permissions
* Developer S3 access
* Finance S3 access
* Excessive direct user policies
* EC2 operational permissions
* EC2 resource restrictions
* EC2 tag restrictions
* Separation of Development and Operations responsibilities

---

# 1. Development IAM Remediation

## Users

The Development department consists of:

* `dev-alice`
* `dev-bob`
* `dev-charlie`
* `dev-david`

## Original Security Problem

The original Development permissions were too broad.

Alice previously had full administrative access through:

```text
fincore-lab-dev-alice-admin
```

The Development group also had EC2 start/stop permissions.

This meant that developers could perform operational actions that should be restricted to the Operations department.

---

## Required Permissions

The Development users only require the ability to inspect EC2 instances.

Required actions:

```text
ec2:DescribeInstanceAttribute
ec2:DescribeInstances
```

The following permissions were removed:

```text
Administrator/full access
ec2:StartInstances
ec2:StopInstances
```

The intended resource scope was:

```text
arn:aws:ec2:eu-west-1:174558682011:instance/*
```

---

## Development Policy

The final Development policy created for the remediation was:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeInstanceAttributeDev",
      "Effect": "Allow",
      "Action": "ec2:DescribeInstanceAttribute",
      "Resource": "arn:aws:ec2:eu-west-1:174558682011:instance/*"
    },
    {
      "Sid": "DescribeInstancesDev",
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    }
  ]
}
```

The policy provides developers with read/inspection capabilities rather than operational control over EC2 instances.

---

# 2. Operations IAM Remediation

## Users

The Operations department consists of:

* `op-george`
* `op-henry`
* `op-irene`

## Original Security Problem

The original Operations policy allowed the users to perform EC2 actions broadly across the AWS account.

The identified permissions included:

* Listing EC2 instances
* Starting EC2 instances
* Stopping EC2 instances
* Changing EC2 instance names

The original access was broader than required.

---

## Required Permissions

Operations users require:

```text
ec2:DescribeInstances
ec2:StartInstances
ec2:StopInstances
```

They also require the ability to modify the **Name** tag of applicable application instances.

However, they should **not** be able to modify arbitrary tags such as:

```text
Role
Environment
Department
Owner
```

---

# 3. Restricting Start/Stop Access to Application Instances

The requirement was that Operations users should only be able to start or stop EC2 instances that have:

```text
Role = Application
```

The policy therefore uses the following resource tag condition:

```json
"StringEquals": {
  "aws:ResourceTag/Role": "Application"
}
```

This prevents the start/stop permission from applying to instances that do not have the required `Role=Application` tag.

The intended resource scope is:

```text
arn:aws:ec2:eu-west-1:174558682011:instance/*
```

---

# 4. Restricting Tag Modification

An important requirement was that Operations users must be able to modify **only the Name tag**.

They should not be able to modify the `Role` tag.

This distinction is important because the `Role` tag is being used as a security condition for the start/stop permissions.

If Operations users could freely change:

```text
Role=Application
```

they could potentially manipulate which instances satisfy the policy condition.

Therefore, the `CreateTags` permission was restricted using:

```json
"ForAllValues:StringEquals": {
  "aws:TagKeys": [
    "Name"
  ]
}
```

This means the allowed tag key is limited to:

```text
Name
```

The policy also requires:

```text
Role = Application
```

on the existing instance.

---

# 5. Final Operations Policy

The final Operations policy was:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DescribeInstances",
      "Effect": "Allow",
      "Action": "ec2:DescribeInstances",
      "Resource": "*"
    },
    {
      "Sid": "StartStopInstances",
      "Effect": "Allow",
      "Action": [
        "ec2:StartInstances",
        "ec2:StopInstances"
      ],
      "Resource": "arn:aws:ec2:eu-west-1:174558682011:instance/*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/Role": "Application"
        }
      }
    },
    {
      "Sid": "EditNameTagOnly",
      "Effect": "Allow",
      "Action": "ec2:CreateTags",
      "Resource": "arn:aws:ec2:eu-west-1:174558682011:instance/*",
      "Condition": {
        "ForAllValues:StringEquals": {
          "aws:TagKeys": [
            "Name"
          ]
        },
        "StringEquals": {
          "aws:ResourceTag/Role": "Application"
        }
      }
    }
  ]
}
```

---

# 6. Policy Iteration and Correction

During development, the Operations policy went through several iterations.

The initial version included additional conditions such as the username pattern and requested AWS region.

The policy was then simplified to focus on the actual authorization requirements.

The final policy uses the EC2 resource tag:

```text
Role = Application
```

to restrict start/stop operations.

The tag modification permission was also refined so that Operations users can modify only:

```text
Name
```

and cannot use the permission to modify the `Role` tag.

This was an important security refinement because the `Role` tag controls eligibility for the EC2 start/stop permission.

---

# 7. Developer Bob   S3 Remediation

## User

```text
dev-bob
```

## Original Security Problem

Bob previously had broad/full S3 access through the direct policy:

```text
fincore-lab-dev-bob-direct
```

This provided access to S3 resources beyond what was required for his development responsibilities.

---

## Required Permissions

Bob only requires access to the Development S3 bucket:

```text
fincore-lab-dev-data
```

Required actions:

```text
s3:ListBucket
s3:GetObject
s3:PutObject
```

The following broad/full S3 access was removed.

---

## Final Bob S3 Policy

The bucket-level permission is:

```json
{
  "Sid": "ListBucket",
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket"
  ],
  "Resource": "arn:aws:s3:::fincore-lab-dev-data"
}
```

Object-level access is restricted to objects within the Development bucket:

```json
{
  "Sid": "upload-bucket",
  "Effect": "Allow",
  "Action": [
    "s3:GetObject",
    "s3:PutObject"
  ],
  "Resource": "arn:aws:s3:::fincore-lab-dev-data/*"
}
```

Therefore Bob's access is limited to the Development data bucket rather than all S3 resources in the AWS account.

---

# 8. Finance S3 Remediation

The Finance policy was also restricted to the Finance team's S3 resources.

The Finance bucket is:

```text
fincore-lab-finance-data
```

The policy allows:

```text
s3:ListBucket
```

on the Finance bucket:

```json
{
  "Sid": "FinanceS3List",
  "Effect": "Allow",
  "Action": [
    "s3:ListBucket"
  ],
  "Resource": "arn:aws:s3:::fincore-lab-finance-data"
}
```

Finance users can download objects from that bucket:

```json
{
  "Sid": "FinanceS3Download",
  "Effect": "Allow",
  "Action": [
    "s3:GetObject"
  ],
  "Resource": "arn:aws:s3:::fincore-lab-finance-data/*"
}
```

This removes unnecessary visibility into unrelated S3 buckets.

---

# 9. Removal of Directly Attached User Policies

One of the important remediation steps was removing the previous direct user-policy attachments.

The Terraform resource:

```hcl
aws_iam_user_policy_attachment
```

was removed for the previously identified direct policies.

The objective was to eliminate unnecessary direct permissions and move toward a more controlled permission model based on department/group policies.

The previous direct policies included excessive permissions such as:

```text
fincore-lab-dev-alice-admin
fincore-lab-dev-bob-direct
fincore-lab-fin-frank-ec2
```

These direct attachments were identified during Task 1 as security findings.

---

# 10. Before and After

## Development

### Before

Developers had excessive EC2 permissions and Alice had administrative access.

### After

Developers receive only the EC2 inspection permissions required for their role.

```text
Development
     
    +-- DescribeInstanceAttribute
    +-- DescribeInstances
```

Start/stop permissions were removed from the Development group.

---

## Operations

### Before

Operations users could start, stop and modify EC2 resources broadly.

### After

Operations users can:

```text
DescribeInstances
        +
Start/Stop only Application instances
        +
Modify only the Name tag
```

The `Role` tag cannot be modified through the policy.

---

## Developer S3

### Before

Bob had broad S3 access.

### After

Bob can access only:

```text
fincore-lab-dev-data
```

with:

```text
ListBucket
GetObject
PutObject
```

---

## Finance S3

### Before

Finance users could discover S3 resources outside their intended scope.

### After

Finance access is restricted to:

```text
fincore-lab-finance-data
```

with:

```text
ListBucket
GetObject
```

---

# 11. Security Principles Applied

The remediation applied several security principles.

### Least Privilege

Users receive only the permissions required for their responsibilities.

### Separation of Responsibilities

Development users no longer receive EC2 operational start/stop permissions.

Operations users are responsible for EC2 operational actions.

### Resource-Level Restrictions

Where appropriate, permissions are restricted to specific AWS resources.

Examples:

```text
fincore-lab-dev-data
fincore-lab-finance-data
```

and:

```text
Role = Application
```

for EC2 operational actions.

### Tag-Based Authorization

EC2 start/stop permissions are restricted using:

```text
aws:ResourceTag/Role = Application
```

### Controlled Tag Modification

Operations users can modify only the:

```text
Name
```

tag rather than arbitrary EC2 tags.

### Removal of Direct Permissions

Previously identified unnecessary direct user-policy attachments were removed.

---

# 12. Terraform Changes

The IAM remediation was implemented through Terraform.

The previous direct policy attachment resources were removed:

```hcl
aws_iam_user_policy_attachment
```

The IAM configuration was updated so that permissions are provided through the intended group/policy structure.

Terraform was used to manage the changes rather than manually modifying the AWS console.

---

# 13. Validation

After modifying the Terraform configuration, the infrastructure was reviewed and applied through Terraform.

The IAM configuration was then reviewed to verify that:

* Development permissions were reduced.
* EC2 start/stop permissions were removed from Development.
* Operations retained required EC2 operational permissions.
* Operations permissions were restricted to Application instances.
* Only the `Name` tag could be modified through the tag permission.
* Bob's S3 access was restricted to the Development bucket.
* Finance S3 access was restricted to the Finance bucket.
* Previously identified direct policy attachments were removed.

---

# 14. Evidence

Screenshots and Terraform output from the remediation process should be stored under:

```text
screenshots/task-02/
```

Recommended evidence includes:

```text
task-02/
+-- developer after remidiation policy.png
+-- operation after remidiation policy.png
+-- bob-s3-policy.png
+-- Finance after remidiation policy.png
+-- direct-policy-removed.png
+-- permission-validation for operation policy.png
```

---

# 15. Lessons Learned

This task demonstrated that least privilege is not simply about removing `AdministratorAccess`.

Permissions need to be evaluated according to:

* The user's role
* The required AWS actions
* The resources involved
* Resource tags
* Group membership
* Direct policy attachments
* Operational responsibilities

A particularly important lesson was the relationship between permissions and security-sensitive tags.

Because the Operations policy uses:

```text
Role = Application
```

as a condition for EC2 start/stop access, allowing Operations users to modify the `Role` tag would weaken the security control.

Therefore, tag permissions were restricted to the `Name` key.

The remediation also demonstrated the value of managing IAM through Terraform because permission changes can be reviewed, tracked and reproduced as code.

---

# Task 2 Status

**Status: Completed**

The major IAM permission findings identified during Task 1 were remediated through Terraform.

The next stage is to continue validating the resulting permissions and proceed with the remaining FinCorp security tasks.
