# Enterprise Landing Zone Architecture - Banking & Clinical Data

## 1. Executive Summary & Objective

This Landing Zone is designed to maximize security, regulatory compliance, and operational reliability for organizations handling highly sensitive datasets under **PCI-DSS**, **HIPAA**, **GDPR**, and **ISO 27001**.

By enforcing declarative guardrails at the GCP Organization level, the platform mitigates operational risks, prevents data exfiltration, ensures complete traceability, and optimizes FinOps management.

---

## 2. Structural Hierarchy

```
Organization (organizations/123456789012)
├── fldr-common
│   ├── fldr-bootstrap (State buckets, KMS CMEK, CI/CD WIF)
│   ├── fldr-security-governance (Audit sinks, Access Policies)
│   └── fldr-networking-hub (Shared VPC Host Project)
├── fldr-production
│   ├── fldr-banking-prod (Core Banking APIs & transactional SQL)
│   └── fldr-clinical-prod (Clinical Data Lake & BigQuery analytics)
├── fldr-non-production
│   ├── fldr-banking-non-prod (Development & QA)
│   ├── fldr-clinical-non-prod (Model training & Analytics dev)
│   ├── fldr-banking-stg (Staging & Pre-production integration)
│   └── fldr-clinical-stg (Staging Data Lake)
└── fldr-sandbox (Isolated playground with non-sensitive data)
```

---

## 3. Core Architectural Pillars

### 3.1 Network Topology (Hub-and-Spoke Shared VPC)
- Centralized Network Host project (`prj-net-shared-hub`).
- Segregated subnets: `sb-banking-prod` (10.10.10.0/24) and `sb-clinical-prod` (10.20.10.0/24).
- Private Google Access (PGA) and Private Service Connect (PSC) for Google APIs (`10.100.100.100`) via private Cloud DNS zones (`*.googleapis.com`, `*.pkg.dev`, `*.gcr.io`) without Internet transit.
- Egress restricted by default (`deny_all_egress`) with granular egress allow rules for Google APIs / PSC endpoints, Cloud NAT, and IAP bastions.

### 3.2 Cryptographic Governance (CMEK)
- Cloud KMS Customer Managed Encryption Keys rotated automatically every 90 days (`7776000s`).
- Destruction prevention enabled on all primary keys in production (`prevent_destroy = true`).
- Enforced on all BigQuery datasets and Cloud Storage buckets via custom CEL constraints.

### 3.3 Security Perimeter (VPC Service Controls) & Environment Tiering
- **Reusable Perimeter Module (`modules/vpc-sc-perimeter`):** Standardizes parameterization of regular and bridge service perimeters, dry-run/enforced transitions, restricted service catalogs, ingress/egress policies, and access levels.
- **Production (`environments/prod`):** Strictly **Enforced** mode (`status`) on `sp_regulated_data_shield` across all supported services (`aiplatform`, `bigquery`, `storage`, `sqladmin`, `cloudkms`, `secretmanager`, `notebooks`, `container`, `artifactregistry`), blocking all data exfiltration attempts.
- **Staging (`environments/stg`):** Pre-production validation perimeter (`sp_stg_data_shield`) with CMEK key validation to test integrations and parity prior to production promotion.
- **Development (`environments/dev`):** **Dry-Run** mode (`use_explicit_dry_run_spec = true`) on `sp_dev_data_shield`, logging violation telemetry in Cloud Logging without interrupting developer velocity and experiment pipelines.

### 3.4 Transversal Security Layer (SCC & Access Transparency)
- **Security Command Center (SCC) Org-Level Alerting:** Real-time finding notification streaming to Pub/Sub for active `HIGH` and `CRITICAL` threats, vulnerability detections, and compliance anomalies, coupled with org-level mute rules for operational noise reduction.
- **Access Approval & Access Transparency:** Mandatory approval workflow and auditability for Google Cloud administrative access to enterprise data and workloads across all services, streaming tamper-proof `cloudaudit.googleapis.com/access_transparency` logs to the central BigQuery compliance sink.

### 3.5 AI Governance & Secure Workloads Template
- Dedicated AI template project (`07-ai-governance`) within the VPC Service Controls perimeter.
- APIs pre-enabled for Vertex AI, Workbench Notebooks, Artifact Registry, Cloud Storage, and BigQuery.
- CMEK encryption enforced across Cloud Storage data lake, Artifact Registry Docker repositories, Vertex AI Tensorboards, and inference Endpoints with automatic 90-day rotation.
- Uniform bucket-level access, public access prevention, and structured AI lifecycle directories (`training-data/`, `models/`).

### 3.6 Keyless CI/CD
- GitHub Actions authentication via Workload Identity Federation (WIF) OIDC tokens.
- Zero long-lived static service account JSON keys stored in repositories.

---

## 4. Reference Architecture Alignment & Design Decisions

This architecture builds upon the foundations of Google Cloud's official enterprise blueprints while incorporating specialized guardrails for AI and regulated workloads:

### 4.1 Foundations & Industry Standards Adopted
- **Google Cloud Landing Zone Design Guide** ([cloud.google.com/architecture/landing-zones](https://cloud.google.com/architecture/landing-zones)): Adoption of phased foundation deployments, Hub-and-Spoke Shared VPC, Private Service Connect (PSC), and centralized immutable audit log routing.
- **Google Cloud Enterprise Foundations Blueprint** ([cloud.google.com/architecture/foundations](https://cloud.google.com/architecture/foundations)): Phased hierarchy, organizational policy guardrails, and keyless CI/CD through Workload Identity Federation.

### 4.2 Custom Design Decisions & Value Innovations
1. **Native AI & Agent Platform Governance (`07-ai-governance`, `docs/ai-governance.md`):**
   - Extends standard blueprint coverage with declarative CEL Custom Constraints (`agent_platform_*`) enforcing CMEK and private VPC networks on Custom Training, Vertex AI Endpoints, and Vector Search.
   - Enforces Vertex AI Workbench policies (`ainotebooks.accessMode`, `ainotebooks.restrictPublicIp`).
2. **Context-Aware IAM with Common Expression Language (CEL) (`04-iam`):**
   - Applies conditional access bindings restricting Legal/Audit and Data Science querying to European business hours (`08:00 - 18:00 UTC`).
   - Limits agent deployment service account impersonation strictly to dedicated workload identities (`sa-agent-training`, `sa-agent-serving`, `sa-agent-vector-search`), preventing privilege escalation.
3. **Multi-Environment VPC-SC Lifecycle Engine (`modules/vpc-sc-perimeter`):**
   - Standardizes regular and bridge perimeters across environments, operating `dev` in explicit Dry-Run (`use_explicit_dry_run_spec`) for telemetry without blocking developer velocity, `stg` for pre-production validation, and `prod` in fully Enforced mode.
4. **Holistic Multi-Layer Security Operations:**
   - Real-time Security Command Center (SCC) streaming finding notifications to Pub/Sub with dev mute configs, Access Approval / Access Transparency for Google staff operations, and 7-year immutable audit retention in BigQuery.
5. **Mandatory EU Data Sovereignty:**
   - Strict `gcp.resourceLocations` constraint allowing only European regions (`in:eu-locations`) for GDPR and EU AI Act compliance.
