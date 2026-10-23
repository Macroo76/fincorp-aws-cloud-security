# FinCorp   Task 6: RDS Security

## Objective

Audit and secure the FinCorp Amazon RDS PostgreSQL database.

The objectives were to:

* Verify that the database is not publicly accessible.
* Verify network isolation of the database subnets.
* Verify that PostgreSQL access is restricted to the application tier.
* Verify encryption at rest and KMS usage.
* Verify automated backups.
* Review deletion protection.
* Review database logging and monitoring.
* Assess Multi-AZ configuration and document the availability trade-off.
* Remediate identified security and operational findings.
* Validate the final configuration using AWS CLI.

---

## 1. RDS Environment

**Database:** `fincore-lab-postgres`

**Engine:** PostgreSQL 16.13

**Instance class:** `db.t3.micro`

**Region:** `eu-west-1`

**Database name:** `fincore`

**DB subnet group:** `fincore-lab-db-subnet-group`

The RDS instance uses two database subnets:

* `subnet-088a3741fa3b9998d`   `eu-west-1a`
* `subnet-0a52fa201a853ca84`   `eu-west-1b`

---

# 2. Initial Security Audit

The RDS configuration was inspected using AWS CLI before remediation.

The initial configuration showed:

* `PubliclyAccessible = false`
* `StorageEncrypted = true`
* KMS key configured
* Backup retention = 7 days
* `DeletionProtection = false`
* `MultiAZ = false`
* PostgreSQL logs were not exported to CloudWatch
* Database security group restricted PostgreSQL access to the application security group

Evidence:

`RDS-Settings-founding.png`

---

# 3. Network Isolation

The RDS DB subnet group uses route table:

`rtb-03672fd0f6f181aa4`

Both database subnets are associated with this route table.

The route table contains only:

```text
Destination: 172.16.0.0/16
Target: local
```

There is no:

```text
0.0.0.0/0 ? Internet Gateway
```

and no:

```text
0.0.0.0/0 ? NAT Gateway
```

Therefore, the database subnets do not have a direct Internet or NAT route.

This was verified using AWS CLI.

### Security conclusion

The database is isolated at the subnet routing level and does not have an Internet path through an Internet Gateway or NAT Gateway.

---

# 4. RDS Public Accessibility

The RDS configuration reported:

```text
PubliclyAccessible = False
```

This confirms that the RDS instance is not configured as publicly accessible.

Combined with the private DB subnet routing, this provides strong network isolation.

### Result

**PASS   RDS is not publicly accessible.**

Evidence:

`RDS-Settings-founding.png`

---

# 5. Database Security Group

The database security group is:

`sg-0b9e185c9dfac18c8`

The inbound PostgreSQL rule is:

```text
Protocol: TCP
Port: 5432
Source: sg-0fb5cc71ca3b1b73a8
Description: PostgreSQL from application
```

There is no:

```text
0.0.0.0/0 ? TCP/5432
```

inbound rule.

The source is the application security group rather than an IP range.

Therefore, PostgreSQL access is restricted to resources associated with the application security group.

### Security conclusion

This implements application-tier-to-database-tier segmentation.

```text
Application EC2
     |
     | TCP/5432
     ?
Application SG
     |
     ?
Database SG
     |
     ?
RDS PostgreSQL
```

### Result

**PASS   PostgreSQL access is restricted to the application security group.**

Evidence:

`SecurityGroup-of-the-RDS.png`

---

# 6. RDS Subnet Group

The RDS subnet group is:

`fincore-lab-db-subnet-group`

It contains subnets in:

* `eu-west-1a`
* `eu-west-1b`

This provides the subnet placement required for a potential Multi-AZ deployment, although the current RDS instance itself is Single-AZ.

Evidence:

`subnet-group-of-the-RDS.png`

---

# 7. Encryption at Rest

The RDS instance reports:

```text
StorageEncrypted = True
```

A KMS key is associated with the database:

```text
arn:aws:kms:eu-west-1:174558682011:key/294c9aab-8f17-4c6f-a879-c637a3ecea55
```

This ensures that RDS storage is encrypted at rest.

### Result

**PASS   RDS storage encryption is enabled.**

Evidence:

`RDS-Settings-after-remediation.png`

---

# 8. Automated Backups

The database has:

```text
BackupRetentionPeriod = 7 days
```

This provides seven days of automated backup retention.

### Result

**PASS   Automated backups are enabled with a seven-day retention period.**

Evidence:

`RDS-Settings-after-remediation.png`

---

# 9. Finding: Deletion Protection Disabled

### Initial state

The initial configuration reported:

```text
DeletionProtection = False
```

### Risk

Without deletion protection, an authorized user or automation with sufficient permissions could accidentally delete the database.

This is particularly relevant for infrastructure managed through Terraform because unintended destructive infrastructure changes could result in database deletion.

### Remediation

Terraform was updated to enable:

```hcl
deletion_protection = true
```

The configuration was successfully applied.

### Verification

The final AWS CLI audit reported:

```text
DeletionProtection = True
```

### Result

**REMEDIATED   RDS deletion protection is enabled.**

Evidence:

* `RDS-Settings-founding.png`
* `RDS-Settings-after-remediation.png`

---

# 10. Finding: PostgreSQL Logs Not Exported to CloudWatch

### Initial state

PostgreSQL logs were not configured for CloudWatch Logs export.

### Risk

Without centralized database logging, security monitoring and incident investigation are more difficult.

Centralized database logs can assist with:

* Authentication investigation
* Database activity analysis
* Troubleshooting
* Incident response
* Centralized monitoring

### Remediation

Terraform was updated with:

```hcl
enabled_cloudwatch_logs_exports = ["postgresql"]
```

The configuration was successfully applied.

### Verification

The final AWS CLI output reported:

```text
Logs
postgresql
```

### Result

**REMEDIATED   PostgreSQL logs are exported to CloudWatch Logs.**

Evidence:

* `RDS-Settings-founding.png`
* `RDS-Settings-after-remediation.png`

---

# 11. Availability Review   Multi-AZ

The database subnet group contains subnets in two Availability Zones:

```text
eu-west-1a
eu-west-1b
```

However:

```text
MultiAZ = False
```

This means the DB subnet group spans multiple Availability Zones, but the RDS instance itself is currently Single-AZ.

### Security classification

This is **not considered a security vulnerability**.

It is primarily an availability and resilience consideration.

For this FinCorp lab, Multi-AZ was intentionally left disabled because the database uses a cost-conscious `db.t3.micro` configuration.

### Production recommendation

Production databases requiring higher availability should consider Multi-AZ deployment to provide automatic failover and improved resilience.

### Result

**ACCEPTED LAB TRADE-OFF   Single-AZ deployment retained to control lab cost.**

Evidence:

* `subnet-group-of-the-RDS.png`
* `RDS-Settings-after-remediation.png`

---

# 12. Other Configuration Considerations

The audit also identified several features that were disabled:

```text
IAMDatabaseAuthenticationEnabled = False
PerformanceInsightsEnabled = False
MonitoringInterval = 0
```

These were not treated as security vulnerabilities for this lab.

### IAM Database Authentication

IAM authentication can be useful where centralized AWS identity-based authentication is desired, but it is not required for the current FinCorp architecture.

### Performance Insights

Performance Insights is primarily a database performance monitoring capability and was not required for this security-focused lab.

### Enhanced Monitoring

Enhanced Monitoring was not enabled because the lab does not require detailed operating-system-level database monitoring.

These controls can be reconsidered for a production deployment according to operational and security requirements.

---

# 13. Final Verification

After Terraform remediation, the RDS configuration was verified using AWS CLI.

Final verified configuration:

```text
BackupDays          7
DeletionProtection  True
Encrypted           True
IAMAuth             False
MultiAZ             False
Public              False
SubnetGroup         fincore-lab-db-subnet-group
Logs                postgresql
```

The KMS key is configured and storage encryption remains enabled.

Evidence:

`RDS-Settings-after-remediation.png`

---

# 14. Final Security Posture

The final architecture provides:

```text
                 Internet
                    X
                    |
              No Internet Route
                    |
        +------------------------+
              Private DB Subnet   
                                  
             RDS PostgreSQL       
               :5432              
        +-----------?------------+
                    |
              Database SG
                    ?
                    |
              TCP/5432 only
                    |
             Application SG
                    ?
                    |
             Private EC2
```

Security controls:

* RDS is not publicly accessible.
* DB subnets have no Internet Gateway route.
* DB subnets have no NAT Gateway route.
* PostgreSQL access is restricted to the application security group.
* Storage encryption is enabled.
* KMS encryption key is configured.
* Automated backups are retained for seven days.
* Deletion protection is enabled.
* PostgreSQL logs are exported to CloudWatch.
* Multi-AZ is intentionally disabled as a lab cost trade-off.

---

# 15. Findings Summary

| Finding                                | Severity           | Status                 |
| -------------------------------------- | ------------------ | ---------------------- |
| RDS publicly accessible                |                    | PASS                   |
| DB subnet has Internet route           |                    | PASS                   |
| PostgreSQL open to Internet            |                    | PASS                   |
| PostgreSQL restricted to App SG        |                    | PASS                   |
| Storage encryption disabled            |                    | PASS                   |
| KMS encryption unavailable             |                    | PASS                   |
| Automated backups disabled             |                    | PASS                   |
| Deletion protection disabled           | Medium             | REMEDIATED             |
| PostgreSQL CloudWatch logging disabled | Medium             | REMEDIATED             |
| Multi-AZ disabled                      | Low / Availability | ACCEPTED LAB TRADE-OFF |
| IAM DB authentication disabled         | Informational      | ACCEPTED               |
| Performance Insights disabled          | Informational      | ACCEPTED               |
| Enhanced Monitoring disabled           | Informational      | ACCEPTED               |

---

# 16. Evidence

The actual evidence captured for Task 6 is:

```text
task6/
+-- RDS-Settings-founding.png
+-- subnet-group-of-the-RDS.png
+-- SecurityGroup-of-the-RDS.png
+-- RDS-Settings-after-remediation.png
```

### Evidence mapping

| Screenshot                           | Demonstrates                                            |
| ------------------------------------ | ------------------------------------------------------- |
| `RDS-Settings-founding.png`          | Initial RDS configuration and security findings         |
| `subnet-group-of-the-RDS.png`        | RDS DB subnet group and Availability Zone placement     |
| `SecurityGroup-of-the-RDS.png`       | PostgreSQL restricted to the application security group |
| `RDS-Settings-after-remediation.png` | Final RDS configuration after security remediation      |

The DB route-table isolation was additionally validated directly through AWS CLI:

```text
rtb-03672fd0f6f181aa4
172.16.0.0/16 ? local
```

No Internet Gateway or NAT Gateway route was present.

---

# 17. Conclusion

Task 6 successfully secured and validated the FinCorp RDS PostgreSQL deployment.

The audit initially identified two actionable configuration weaknesses: disabled deletion protection and lack of PostgreSQL CloudWatch log export. Both were remediated through Terraform and verified through AWS CLI.

The database was also confirmed to be privately deployed, encrypted with KMS, protected by automated backups, and restricted to the application security group.

The Single-AZ configuration was intentionally retained as a cost-conscious lab decision rather than incorrectly treating it as a security vulnerability.

**Task 6 Status: COMPLETE**
