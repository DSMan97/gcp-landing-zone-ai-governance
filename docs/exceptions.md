# Policy Exceptions & Governance Management

## 1. Exception Process Overview

All organization policies, custom constraints, and VPC Service Controls perimeters are enforced by default. When an application requires a formal exception (e.g., third-party SaaS integration, external SFTP bridge), the change must follow this lifecycle:

1. **Submission:** Business justification and threat impact submitted to the Cloud Architecture & Security Board.
2. **Review:** Automated risk scoring against PCI-DSS and HIPAA requirements.
3. **Approval:** Dual sign-off required from CISO and Compliance Officer.
4. **Implementation:** Scoped strictly to specific folder or project ID using Terraform tags/labels and branch approvals.
5. **Periodic Review:** Automated expiration review every 90 days.

---

## 2. Registered Exception Schema

When adding an exception in Terraform, declare the metadata within `exceptions.tf` or project variables:

```hcl
variable "approved_exception" {
  type = object({
    ticket_id       = string # e.g. SEC-EXC-2026-089
    requester       = string # e.g. payments-lead@bank.com
    reason          = string # Justification
    expiry_date     = string # RFC3339 timestamp
    target_resource = string # Resource URI
  })
}
```
