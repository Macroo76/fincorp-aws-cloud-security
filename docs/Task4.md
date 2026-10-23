# Task 04   MFA & IAM Credential Security

## Objective

Strengthen IAM credential security for the FinCorp environment by implementing Multi-Factor Authentication (MFA) controls for sensitive Operations activities.

The primary objectives were:

* Audit the MFA status of FinCorp human IAM users.
* Confirm that previously identified long-lived access keys had already been removed.
* Configure MFA for a FinCorp Operations user.
* Require MFA for sensitive EC2 Operations actions.
* Ensure Operations users can only manage EC2 instances tagged `Role=Application`.
* Validate that sensitive actions are denied without MFA and allowed when MFA is present.
* Capture evidence demonstrating the effectiveness of the controls.

---

## 1. Scope

The AWS account contained IAM users unrelated to the FinCorp environment.

The Task 4 changes were therefore scoped exclusively to the nine FinCorp human users:

### Development

* `dev-alice`
* `dev-bob`
* `dev-charlie`
* `dev-david`

### Finance

* `fin-emma`
* `fin-frank`

### Operations

* `op-george`
* `op-henry`
* `op-irene`

This avoided modifying unrelated IAM users in the AWS account.

---

## 2. Initial MFA Assessment

Before implementing the MFA controls, the MFA status of all nine FinCorp users was checked.

The result was:

```text
dev-alice : NO MFA
dev-bob : NO MFA
dev-charlie : NO MFA
dev-david : NO MFA
fin-emma : NO MFA
fin-frank : NO MFA
op-george : NO MFA
op-henry : NO MFA
op-irene : NO MFA
```

This established that none of the nine FinCorp IAM users had an MFA device configured at the beginning of Task 4.

---

## 3. Access Key Verification

Long-lived IAM access keys were also checked during the Task 4 assessment.

No active access keys were found for the nine FinCorp users.

This was not a new remediation in Task 4.

The access keys had already been removed during **Task 2   IAM Least Privilege Remediation**.

Task 4 therefore focused specifically on MFA rather than repeating the access-key remediation.

---

## 4. MFA Security Design

The existing Operations IAM policy allowed Operations users to:

* Describe EC2 instances.
* Start EC2 instances.
* Stop EC2 instances.
* Modify the `Name` tag.

The policy had already been restricted using the following least-privilege controls:

```text
Role = Application
```

for EC2 start/stop operations, and:

```text
TagKeys = Name
```

for tag modification.

Task 4 added another security requirement:

```text
aws:MultiFactorAuthPresent = true
```

Sensitive Operations actions therefore require both:

```text
Role = Application
```

and:

```text
MFA = true
```

---

## 5. Terraform Policy Change

The Operations policy was updated through Terraform.

The relevant policy configuration became:

```json
{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "DescribeInstances",
        "Effect" : "Allow",
        "Action" : "ec2:DescribeInstances",
        "Resource" : "*"
      },
      {
        "Sid" : "StartStopInstances",
        "Effect" : "Allow",
        "Action" : [
          "ec2:StartInstances",
          "ec2:StopInstances"
        ],
        "Resource" : "arn:aws:ec2:${region}:${account}:instance/*",
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/Role" : "Application"
          },
          "Bool" : {
            "aws:MultiFactorAuthPresent" : "true"
          }
        }
      },
      {
        "Sid" : "EditNameTagOnly",
        "Effect" : "Allow",
        "Action" : "ec2:CreateTags",
        "Resource" : "arn:aws:ec2:${region}:${account}:instance/*",
        "Condition" : {
          "ForAllValues:StringEquals" : {
            "aws:TagKeys" : ["Name"]
          },
          "StringEquals" : {
            "aws:ResourceTag/Role" : "Application"
          },
          "Bool" : {
            "aws:MultiFactorAuthPresent" : "true"
          }
        }
      }
    ]
}
```

### Result

The policy was successfully applied through Terraform.

The resulting authorization model is:

| Action                  | MFA Required | Resource Restriction                |
| ----------------------- | ------------ | ----------------------------------- |
| `ec2:DescribeInstances` | No           | All resources                       |
| `ec2:StartInstances`    | Yes          | `Role=Application`                  |
| `ec2:StopInstances`     | Yes          | `Role=Application`                  |
| `ec2:CreateTags`        | Yes          | `Role=Application` + `TagKeys=Name` |

This maintains the least-privilege controls established in Task 2 while adding MFA protection to sensitive operations.

---

## 6. Creating the Virtual MFA Device

A virtual MFA device was created for the Operations user `op-george`.

Command:

```powershell
aws iam create-virtual-mfa-device `
  --virtual-mfa-device-name op-george `
  --bootstrap-method QRCodePNG `
  --outfile mfa-george.png
```

AWS returned the MFA device ARN:

```text
arn:aws:iam::174558682011:mfa/op-george
```

At this stage the virtual MFA device existed in the AWS account but was not yet attached to the IAM user.

Evidence:

```text
screenshots/task4/MFA-config.png
```

---

## 7. Attaching MFA to op-george

The MFA device was enabled and associated with `op-george` using two consecutive authentication codes from the authenticator application.

The configuration was then verified using:

```powershell
aws iam list-mfa-devices --user-name op-george
```

The successful result showed:

```json
{
    "MFADevices": [
        {
            "UserName": "op-george",
            "SerialNumber": "arn:aws:iam::174558682011:mfa/op-george",
            "EnableDate": "2026-09-30T09:13:43+00:00"
        }
    ]
}
```

This confirmed that the MFA device was successfully enabled for the IAM user.

Evidence:

```text
screenshots/task4/op-george-mfa-attached.png
```

---

## 8. MFA Authorization Validation

The IAM Policy Simulator was used to validate the MFA condition.

The tests were performed against an EC2 instance satisfying the Operations policy requirement:

```text
Role = Application
```

### Test 1   StartInstances without MFA

The Policy Simulator was configured with:

```text
aws:MultiFactorAuthPresent = false
```

The result was:

```text
StartInstances ? Denied
```

This demonstrated that the MFA condition prevents the Operations user from starting the Application instance when the request does not contain the required MFA context.

Evidence:

```text
screenshots/task4/without-MFA.png
```

---

### Test 2   StartInstances with MFA

The same authorization test was repeated with:

```text
aws:MultiFactorAuthPresent = true
```

The result was:

```text
StartInstances ? Allowed
```

This demonstrated that the MFA condition is satisfied when MFA is present, provided the other policy conditions are also satisfied.

Evidence:

```text
screenshots/task4/with-MFA.png
```

---

### Test 3   StopInstances

The same MFA validation was performed for:

```text
ec2:StopInstances
```

The results confirmed the intended behavior:

```text
MFA = false ? Denied
MFA = true  ? Allowed
```

This verified that both sensitive EC2 lifecycle operations are protected by MFA.

---

## 9. Security Control Result

The final authorization model for the Operations users is:

```text
                    Operations User
                           
                          ?
                 EC2 Start / Stop
                           
              +-----------------------+
                                       
       Role=Application?         MFA present?
                                       
             YES                     YES
                                       
              +-----------------------+
                           
                          ?
                       ALLOW
```

If either condition is not satisfied:

```text
Role != Application
        OR
MFA != true
        ?
      DENY
```

This provides layered authorization rather than relying on a single access control.

---

## 10. Troubleshooting

### Issue: MFA device existed but was not attached

After creating the virtual MFA device, the following command returned an empty list:

```powershell
aws iam list-mfa-devices --user-name op-george
```

The virtual device existed in the account, but it had not yet been enabled for the IAM user.

The distinction was:

```text
create-virtual-mfa-device
        ?
Creates virtual MFA device
        ?
Device exists but is unassigned
        ?
enable-mfa-device
        ?
Device becomes associated with IAM user
```

After enabling it, `list-mfa-devices` correctly returned the `op-george` MFA device.

---

### Issue: Incorrect command used to list virtual MFA devices

The following command was initially attempted:

```powershell
aws iam list-virtual-mfa-devices --user-name op-george
```

AWS returned an error because `list-virtual-mfa-devices` does not accept the `--user-name` parameter.

The correct command is:

```powershell
aws iam list-virtual-mfa-devices
```

This lists virtual MFA devices in the AWS account.

---

### Policy Simulator initially returned Denied

The Policy Simulator initially returned:

```text
StartInstances ? Denied
StopInstances ? Denied
```

The simulation needed to satisfy all relevant policy conditions, not only the MFA condition.

The Operations policy requires:

```text
aws:MultiFactorAuthPresent = true
```

and:

```text
aws:ResourceTag/Role = Application
```

The simulation was therefore performed against an appropriate Application EC2 instance with the correct resource-tag context.

After configuring the simulation correctly, the expected difference was demonstrated:

```text
Without MFA ? Denied
With MFA    ? Allowed
```

---

## 11. Evidence

Task 4 evidence is stored in:

```text
screenshots/task4/
```

Files:

```text
MFA-config.png
op-george-mfa-attached.png
with-MFA.png
without-MFA.png
```

### Evidence mapping

| Evidence                     | Demonstrates                              |
| ---------------------------- | ----------------------------------------- |
| `MFA-config.png`             | Virtual MFA device creation/configuration |
| `op-george-mfa-attached.png` | MFA successfully attached to `op-george`  |
| `without-MFA.png`            | Sensitive EC2 action denied without MFA   |
| `with-MFA.png`               | Sensitive EC2 action allowed with MFA     |

---

## 12. Lessons Learned

### MFA registration is different from MFA enforcement

Creating an MFA device alone does not enforce MFA-based authorization.

The IAM policy must explicitly evaluate MFA context, for example:

```json
"Bool": {
    "aws:MultiFactorAuthPresent": "true"
}
```

---

### Least privilege and MFA work together

MFA should not replace least privilege.

The Operations policy uses multiple controls:

```text
MFA
+
Resource tags
+
Restricted tag keys
+
Limited EC2 actions
```

This creates layered authorization.

---

### Resource tags can provide an authorization boundary

The Operations users are allowed to start and stop only instances tagged:

```text
Role=Application
```

This prevents the same permission from automatically applying to every EC2 instance in the account.

---

### Tag modification must also be restricted

Allowing `ec2:CreateTags` without restrictions could allow an Operations user to manipulate authorization-related tags.

The policy therefore restricts the allowed tag key to:

```text
Name
```

This prevents the user from changing the `Role` tag to bypass the Application-instance restriction.

---

### Avoid unnecessary long-lived credentials

The FinCorp IAM users no longer have the long-lived access keys that were identified during the earlier security audit.

Task 4 therefore strengthened authentication without reintroducing long-lived credentials merely for testing.

---

## 13. Task Completion

**Status: COMPLETE**

Task 4 successfully implemented and validated MFA-based protection for sensitive FinCorp Operations activities.

The final control ensures that Operations users require MFA before performing sensitive EC2 actions while maintaining the resource and tag restrictions established during the least-privilege remediation.

The implementation was performed through Terraform and validated using the AWS IAM Policy Simulator.
