# Task 7 — S3 Security

## Objective

Secure and audit the FinCorp S3 infrastructure with a focus on:

* Public access prevention
* Object ownership and ACL security
* Encryption at rest
* Versioning
* Secure transport
* Bucket policy least privilege
* CloudTrail logging
* Data retention and lifecycle management

The objective was not to enable every available AWS security feature, but to evaluate each control based on its security value and the purpose of the bucket.

---

# 1. Initial S3 Inventory

The initial S3 inventory was performed using:

```powershell
aws s3api list-buckets `
  --query "Buckets[].Name" `
  --output table
```

The account contained one S3 bucket:

```text
fincore-lab-logs-174558682011
```

This bucket is dedicated to storing AWS CloudTrail logs.

No separate application data buckets were present at the time of the audit.

---

# 2. Initial Security Audit

The following controls were audited before remediation:

```powershell
aws s3api get-public-access-block --bucket fincore-lab-logs-174558682011
aws s3api get-bucket-encryption --bucket fincore-lab-logs-174558682011
aws s3api get-bucket-versioning --bucket fincore-lab-logs-174558682011
aws s3api get-bucket-ownership-controls --bucket fincore-lab-logs-174558682011
aws s3api get-bucket-policy --bucket fincore-lab-logs-174558682011
aws s3api get-bucket-acl --bucket fincore-lab-logs-174558682011
```

## Initial findings

### Finding 1 — HTTPS-only transport was not explicitly enforced

The initial bucket policy did not contain an explicit `aws:SecureTransport` deny condition.

Although the bucket was not publicly accessible, there was no explicit policy-level control preventing access over insecure transport.

**Risk:** Low/Medium

**Recommendation:** Add an explicit deny for all S3 operations where `aws:SecureTransport` is `false`.

---

### Finding 2 — No lifecycle/retention policy

The following command returned:

```text
NoSuchLifecycleConfiguration
```

This indicated that the CloudTrail log bucket had no lifecycle configuration.

**Risk:** Low/Medium

Without an explicit retention policy, CloudTrail objects could accumulate indefinitely, increasing storage consumption and potentially conflicting with an intended retention requirement.

**Recommendation:** Define an explicit retention policy appropriate for the environment.

For this lab, a 365-day retention period was selected.

---

### Finding 3 — Object Ownership was not explicitly managed by Terraform

AWS reported:

```text
ObjectOwnership = BucketOwnerEnforced
```

The bucket was already using the secure ownership configuration, but the setting was not explicitly represented in the Terraform configuration.

**Risk:** Low

**Recommendation:** Declare `BucketOwnerEnforced` explicitly in Terraform to make the security posture reproducible and prevent configuration drift.

---

# 3. Controls That Already Passed

Several controls were already correctly implemented and therefore did not require remediation.

## Public Access Block

The bucket returned:

```json
{
  "BlockPublicAcls": true,
  "IgnorePublicAcls": true,
  "BlockPublicPolicy": true,
  "RestrictPublicBuckets": true
}
```

**Result: PASS**

All four S3 Block Public Access controls were enabled.

---

## Encryption

The bucket used:

```text
SSEAlgorithm = AES256
```

This means S3-managed server-side encryption (SSE-S3) was enabled by default.

**Result: PASS**

SSE-S3 was considered sufficient for this dedicated CloudTrail log bucket. Customer-managed KMS encryption was not treated as a vulnerability because the security requirement did not require it.

---

## Versioning

The bucket returned:

```text
Status = Enabled
```

**Result: PASS**

Versioning provides protection against accidental overwrites and deletions and supports the retention strategy for the bucket.

---

## Object Ownership

AWS reported:

```text
BucketOwnerEnforced
```

This disables ACL-based access control for the bucket.

**Result: PASS**

The configuration was subsequently declared explicitly in Terraform.

---

## ACL

The bucket ACL contained only the bucket owner with:

```text
FULL_CONTROL
```

There were no public or unexpected ACL grants.

**Result: PASS**

---

# 4. CloudTrail Bucket Policy Audit

The original bucket policy granted CloudTrail only the permissions required to deliver logs:

### CloudTrail ACL check

```text
s3:GetBucketAcl
```

### CloudTrail log delivery

```text
s3:PutObject
```

The object resource was restricted to:

```text
AWSLogs/<AWS_ACCOUNT_ID>/*
```

and required:

```text
s3:x-amz-acl = bucket-owner-full-control
```

**Result: PASS**

The policy follows the principle of least privilege for CloudTrail log delivery.

---

# 5. Remediation

## 5.1 Explicit Object Ownership

The following Terraform resource was added:

```hcl
resource "aws_s3_bucket_ownership_controls" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

The CloudTrail resource was also made dependent on the ownership configuration:

```hcl
depends_on = [
  aws_s3_bucket_policy.cloudtrail,
  aws_s3_bucket_ownership_controls.logs
]
```

This ensures the intended ownership configuration is explicitly managed by Terraform.

---

# 5.2 HTTPS-only enforcement

The following statement was added to the bucket policy:

```hcl
{
  Sid    = "DenyInsecureTransport"
  Effect = "Deny"

  Principal = "*"

  Action = "s3:*"

  Resource = [
    aws_s3_bucket.logs.arn,
    "${aws_s3_bucket.logs.arn}/*"
  ]

  Condition = {
    Bool = {
      "aws:SecureTransport" = "false"
    }
  }
}
```

This applies the control to both:

```text
arn:aws:s3:::bucket
```

and:

```text
arn:aws:s3:::bucket/*
```

The first represents the bucket itself, while the second represents objects inside the bucket.

The result is an explicit policy-level requirement for secure transport.

---

# 5.3 Lifecycle and retention

A lifecycle configuration was added:

```hcl
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "cloudtrail-log-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}
```

The selected lab retention policy is:

* Current objects: 365 days
* Noncurrent versions: 365 days

The empty prefix means the rule applies to all objects in the dedicated CloudTrail bucket.

This retention period is a **lab-defined policy** and is not intended to represent a universal production retention requirement.

---

# 6. CloudTrail Security Audit

CloudTrail was verified using:

```powershell
aws cloudtrail describe-trails `
  --region eu-west-1 `
  --output json
```

The trail:

```text
fincore-lab-cloudtrail
```

was configured with:

```text
IncludeGlobalServiceEvents = true
IsMultiRegionTrail        = true
LogFileValidationEnabled  = true
```

The CloudTrail status was then checked:

```powershell
aws cloudtrail get-trail-status `
  --name fincore-lab-cloudtrail `
  --region eu-west-1 `
  --output json
```

The result confirmed:

```text
IsLogging = true
```

and showed successful recent log delivery.

**Result: PASS**

---

# 7. CloudTrail Event Selection

The CloudTrail event selectors returned:

```json
{
  "ReadWriteType": "All",
  "IncludeManagementEvents": true,
  "DataResources": []
}
```

This means management events are being recorded, while S3 data events are not enabled.

This was **not treated as a vulnerability**.

The only S3 bucket in the environment is the dedicated CloudTrail log bucket. Enabling object-level data events for that same log bucket would introduce additional event volume and cost without providing significant value for this lab.

If future FinCorp application buckets containing sensitive business data are introduced, S3 data events should be evaluated for those buckets.

---

# 8. Final S3 Security Posture

| Control                       | Final Status                                 |
| ----------------------------- | -------------------------------------------- |
| Block Public ACLs             | PASS                                         |
| Ignore Public ACLs            | PASS                                         |
| Block Public Policies         | PASS                                         |
| Restrict Public Buckets       | PASS                                         |
| BucketOwnerEnforced           | PASS                                         |
| Public ACL exposure           | PASS                                         |
| SSE-S3 encryption             | PASS                                         |
| Versioning                    | PASS                                         |
| HTTPS-only transport          | PASS                                         |
| CloudTrail bucket policy      | PASS                                         |
| CloudTrail logging            | PASS                                         |
| Multi-region CloudTrail       | PASS                                         |
| Global service events         | PASS                                         |
| Log file validation           | PASS                                         |
| Lifecycle retention           | PASS                                         |
| Noncurrent version expiration | PASS                                         |
| S3 data events                | Informational — not required for this bucket |

---

# 9. Final Verification

The lifecycle configuration was verified with:

```powershell
aws s3api get-bucket-lifecycle-configuration `
  --bucket fincore-lab-logs-174558682011 `
  --output json
```

The final result confirmed:

```json
{
  "Rules": [
    {
      "Expiration": {
        "Days": 365
      },
      "ID": "cloudtrail-log-retention",
      "Filter": {
        "Prefix": ""
      },
      "Status": "Enabled",
      "NoncurrentVersionExpiration": {
        "NoncurrentDays": 365
      }
    }
  ]
}
```

The bucket therefore has an active 365-day retention policy for both current and noncurrent object versions.

---

# 10. Security Lessons

### 1. Public access protection is not the same as transport security

Block Public Access prevents public exposure, but it does not replace an explicit HTTPS-only policy.

### 2. Security controls should be evaluated based on context

Not every AWS security feature needs to be enabled everywhere.

S3 data events were not enabled for the CloudTrail log bucket because object-level auditing of the logging destination itself provided limited additional value for this lab.

### 3. Terraform should represent the intended security state

Even when AWS already had `BucketOwnerEnforced`, explicitly managing it through Terraform makes the configuration reproducible and easier to audit.

### 4. Retention is a security and operational decision

A lifecycle policy prevents indefinite accumulation, but the retention period must be based on organizational, regulatory, and incident-response requirements.

### 5. Explicit Deny is a strong defense-in-depth control

The `DenyInsecureTransport` statement ensures that an otherwise permitted S3 operation cannot be performed over insecure transport.

---

# 11. Task 7 Conclusion

**Task 7 — S3 Security: COMPLETE**

The FinCorp S3 infrastructure was audited and hardened against public exposure, insecure transport, unmanaged object ownership, and indefinite log accumulation.

The final configuration follows least privilege, defense-in-depth, infrastructure-as-code principles, and context-driven security design.