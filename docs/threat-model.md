# Threat Model & Risk Mitigation Matrix

## 1. Threat Modeling Overview (STRIDE Methodology)

| Threat Category | Attack Vector | Landing Zone Countermeasure | Verification Mechanism |
| :--- | :--- | :--- | :--- |
| **Spoofing** | Compromised CI/CD credentials / Stolen SA keys / Agent Identity Impersonation | Workload Identity Federation (WIF) OIDC tokens; `iam.disableServiceAccountKeyCreation` org policy; CEL conditions restricting deployers to `sa-agent-*` | Automated policy enforcement; absence of JSON keys; IAM policy evaluation |
| **Tampering** | Unauthorized state modification, log tampering, or model/dataset poisoning | Immutable BigQuery Dataset with locked retention (2555 days); KMS CMEK encryption; GCS versioning; Artifact Registry container scanning & immutability | Audit logs integrity check, BigQuery access control & KMS key rotation audit |
| **Repudiation** | Unaudited data access or unmonitored AI model / RAG invocations | `google_organization_iam_audit_config` with mandatory `DATA_READ` & `DATA_WRITE` logging for `aiplatform.googleapis.com`, `bigquery.googleapis.com`, and `storage.googleapis.com` | Real-time SIEM ingestion from BigQuery aggregated sink (`ds_audit_compliance_logs`) |
| **Information Disclosure** | Data exfiltration via public endpoints, storage buckets, or Vector Search | VPC Service Controls (`sp_regulated_data_shield`), `compute.vmExternalIpAccess (Deny All)`, `sql.restrictPublicIp`, CEL constraints enforcing private VPCs & CMEK on Vertex AI | Preventative CEL guardrails, VPC-SC violation metrics & perimeter status |
| **Denial of Service** | Rogue resource provisioning, crypto-mining, or quota exhaustion by runaway models | Org policy `gcp.resourceLocations` (EU-only), `compute.skipDefaultNetworkCreation`, FinOps quotas and alerts | Policy evaluation on `google_project_service` & FinOps billing monitors |
| **Elevation of Privilege** | Permanent admin escalation or prompt injection altering agent behavior | Least Privilege IAM with CEL time-bound conditions; strictly scoped `sa-agent-serving` service account (no IAM admin / no KMS decryption rights); PSC isolation | Periodic IAM automated scans, static policy audits & Cloud Audit logs |

---

## 2. AI & Autonomous Agent Threat Vectors

| AI Threat Category | Specific Attack Vector | Countermeasure in Landing Zone | Reference Module |
| :--- | :--- | :--- | :--- |
| **Prompt Injection** (Direct & Indirect) | Adversarial prompts in user input or poisoned RAG documents manipulating agent execution | Dedicated `sa-agent-serving` with minimal read-only scope; API execution restricted via Private Service Connect and internal VPC; absence of privilege escalation paths | `foundation/04-iam`, `foundation/06-networking` |
| **Model & Data Exfiltration** | Model weights theft, training dataset scraping, or unencrypted endpoint leaks | VPC-SC perimeter restricting `aiplatform.googleapis.com`; CEL custom constraints requiring private VPC and CMEK on all CustomJobs and Endpoints; Workbench file download block | `foundation/02-org-policies`, `foundation/03-custom-constraints`, `foundation/06-networking`, `foundation/07-ai-governance` |
| **Non-EU Data Residency Violation** | Training or serving models in foreign jurisdictions breaching GDPR/EU AI Act | Org Policy `gcp.resourceLocations` forcing `in:eu-locations` (`europe-west1`, `europe-west4`); Cloud KMS KeyRings and GCS buckets strictly regionalized in EU | `foundation/02-org-policies`, `foundation/07-ai-governance` |
| **Unauthorized Model Access & Tampering** | Unauthorized inference invocation or alteration of production endpoints | Role separation (Data Scientists vs Agent Deployers vs AI Auditors) with CEL conditions; audit trail for all model predictions and artifact deployments | `foundation/04-iam`, `foundation/05-logging`, `docs/ai-governance.md` |

---

## 3. Risk Mitigation Impact

1. **Blast Radius Minimization:** Segmentation across dedicated folders and projects prevents lateral movement between banking transactional systems, clinical analytics, and AI model pipelines.
2. **Deterministic Data Resiliency:** 7-year immutable audit trail ensures auditability for regulatory inquiries under Basel III, PCI-DSS requirement 10, HIPAA §164.312(b), and EU AI Act Article 12.
3. **Sovereign AI Governance & Confidentiality:** Strict EU data residency (`europe-*`), private VPC execution, and CMEK protection prevent cross-tenant model exposure and unauthorized training data exfiltration.
4. **Resilient Agent Execution:** Hardened identity boundaries and defense-in-depth networking prevent prompt injection attacks from compromising underlying cloud infrastructure.
