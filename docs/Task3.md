# Task 3   IAM Permissions Boundary for Development Users

## Objective

Implement an AWS IAM Permissions Boundary for all Development users to provide an additional security guardrail and prevent future identity-based policies from granting permissions beyond the approved Development security boundary.

The boundary was applied to:

* `dev-alice`
* `dev-bob`
* `dev-charlie`
* `dev-david`

This task builds on the least-privilege remediation performed in Task 2.

---

## Background

In Task 2, excessive IAM permissions were removed from the Development users and their permissions were moved toward least privilege.

However, least-privilege policies alone do not prevent a future administrator from accidentally attaching a broader policy to a Development user.

For example, a future policy could accidentally grant:

```text
ec2:TerminateInstances
s3:DeleteBucket
iam:CreateUser
```

A Permissions Boundary provides an additional control that limits the maximum permissions that can be granted to these users.

---

## Permissions Boundary

The customer-managed IAM policy created for the Development users is:

```text
fincore-lab-developer_boundary
```

Policy ARN:

```text
arn:aws:iam::174558682011:policy/fincore-lab-developer_boundary
```

The boundary was applied to all four Development users.

---

## Users Protected

| User          | Department  | Permissions Boundary             |
| ------------- | ----------- | -------------------------------- |
| `dev-alice`   | Development | `fincore-lab-developer_boundary` |
| `dev-bob`     | Development | `fincore-lab-developer_boundary` |
| `dev-charlie` | Development | `fincore-lab-developer_boundary` |
| `dev-david`   | Development | `fincore-lab-developer_boundary` |

Evidence:

* [Alice Permissions Boundary](../screenshots/task3/alice-permissions-boundary.png)
* [Bob Permissions Boundary](../screenshots/task3/bob-permissions-boundary.png)
* [Charlie Permissions Boundary](../screenshots/task3/charlie-permissions-boundary.png)
* [David Permissions Boundary](../screenshots/task3/david-permissions-boundary.png)

---

## Terraform Implementation

The Permissions Boundary was implemented using Terraform.

The Terraform configuration:

1. Created the customer-managed IAM policy.
2. Assigned the policy as a permissions boundary to `dev-alice`.
3. Assigned the policy as a permissions boundary to `dev-bob`.
4. Assigned the policy as a permissions boundary to `dev-charlie`.
5. Assigned the policy as a permissions boundary to `dev-david`.

The Terraform deployment completed successfully:

```text
Apply complete! Resources: 1 added, 4 changed, 0 destroyed.
```

This indicates that:

* 1 IAM policy was created.
* 4 IAM users were modified.
* No existing FinCorp resources were destroyed.

---

## Permissions Boundary Concept

A Permissions Boundary does **not** grant permissions to a user.

Instead, it defines the maximum permissions that identity-based policies can grant.

Conceptually:

```text
Identity Policy
       +
Permissions Boundary
       ?
Effective Permissions
```

If an identity policy grants an action but the Permissions Boundary does not allow that action, the user cannot effectively perform it.

An explicit `Deny` also overrides an `Allow`.

---

## Security Scenario

Consider `dev-alice`.

Suppose a future administrator accidentally attaches an identity policy containing:

```json
{
  "Effect": "Allow",
  "Action": "ec2:TerminateInstances",
  "Resource": "*"
}
```

If `ec2:TerminateInstances` is outside the permissions allowed by the Development Permissions Boundary, the effective permission remains denied.

This provides an additional protection layer against:

* Accidental privilege escalation
* Overly broad future IAM policies
* Administrative mistakes
* Excessive permissions being introduced later

---

## Validation

After deployment, the Permissions Boundary was verified on each Development user.

The following users were checked:

```text
dev-alice
dev-bob
dev-charlie
dev-david
```

The AWS IAM user details confirmed that each user had:

```text
PermissionsBoundary:
arn:aws:iam::174558682011:policy/fincore-lab-developer_boundary
```

### Alice

Evidence:

`alice-permissions-boundary.png`

### Bob

Evidence:

`bob-permissions-boundary.png`

### Charlie

Evidence:

`charlie-permissions-boundary.png`

### David

Evidence:

`david-permissions-boundary.png`

---

## Boundary Policy Verification

The customer-managed boundary policy was also verified in AWS.

Evidence:

`boundary-policy.png`

This confirms that the intended Permissions Boundary policy exists and is available in the AWS account.

---

## IAM Policy Simulator Validation

The IAM Policy Simulator was used to validate the effective permissions of `dev-alice`.

The test was performed against the Development user's permissions to verify the resulting authorization behavior.

Evidence:

`policy-simulator-alice.png`

This provides additional validation beyond simply confirming that the boundary ARN is attached to the user.

---

## Important Testing Consideration

A Permissions Boundary should be distinguished from an ordinary identity-policy denial.

For example, if a user has no policy granting:

```text
ec2:TerminateInstances
```

the action may already be denied regardless of whether a Permissions Boundary exists.

Therefore, the strongest boundary validation is performed by evaluating the interaction between:

1. Identity-based permissions
2. The Permissions Boundary
3. The resulting effective permissions

The Policy Simulator was used as part of this validation process.

---

## Troubleshooting

During the Terraform deployment, an initial DNS/connectivity error occurred while communicating with AWS.

The issue was transient. A subsequent Terraform operation completed successfully.

Final result:

```text
Apply complete! Resources: 1 added, 4 changed, 0 destroyed.
```

No infrastructure resources were destroyed as a result of this issue.

---

## Security Benefits

The Permissions Boundary provides an additional IAM security control for the Development department.

### 1. Defense in Depth

Least-privilege policies from Task 2 remain in place while the Permissions Boundary provides another security layer.

### 2. Protection Against Future Policy Changes

If a broader identity policy is accidentally attached to a Development user, the Permissions Boundary can restrict the resulting effective permissions.

### 3. Reduced Privilege Escalation Risk

Development users are prevented from effectively receiving permissions outside the approved boundary.

### 4. Centralized Control

The organization can update the boundary policy to change the maximum permissions permitted for Development users.

### 5. Separation of Responsibilities

Development users remain separated from administrative and operational capabilities that are not required for their role.

---

## Relationship With Task 2

Task 2 and Task 3 provide different security controls.

### Task 2   Least Privilege

Task 2 defines what Development users should be allowed to do.

For example:

```text
Describe EC2 instances
```

and removes unnecessary capabilities such as:

```text
StartInstances
StopInstances
```

### Task 3   Permissions Boundary

Task 3 defines the maximum permissions that Development users can receive through identity-based policies.

Therefore:

```text
Task 2
Least-privilege permissions
        +
Task 3
Permissions Boundary
        =
Defense in depth
```

---

## Evidence

The following evidence was captured for Task 3:

### Development User Boundaries

```text
screenshots/task3/alice-permissions-boundary.png
screenshots/task3/bob-permissions-boundary.png
screenshots/task3/charlie-permissions-boundary.png
screenshots/task3/david-permissions-boundary.png
```

### Boundary Policy

```text
screenshots/task3/boundary-policy.png
```

### Policy Simulator

```text
screenshots/task3/policy-simulator-alice.png
```

---

## Lessons Learned

* A Permissions Boundary does not grant permissions; it limits the maximum permissions that can be granted through identity-based policies.
* Least privilege and Permissions Boundaries serve different purposes and can be combined for defense in depth.
* IAM security should account for both current permissions and future policy changes.
* Policy Simulator is useful for validating effective permissions rather than only checking whether a policy is attached.
* Terraform allows IAM security controls to be implemented consistently and reproducibly.
* Successful Terraform deployment should be followed by independent AWS-side validation.

---

## Task 3 Status

**Completed   Implemented, Validated, and Evidence Captured**

The IAM Permissions Boundary was successfully created and applied to all four Development users.

The configuration was subsequently validated through AWS IAM user inspection, boundary policy verification, and IAM Policy Simulator testing.

No existing FinCorp infrastructure was destroyed during the implementation.
