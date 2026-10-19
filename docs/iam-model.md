# IAM Model & Conditional Access (Least Privilege)

## 1. Role Architecture & Persona Separation

To ensure strict separation of duties and maximize operational security, IAM roles are assigned to centralized Google Groups and automated Service Accounts rather than individual user accounts.

```
+----------------------------------------------------------------------------------------------------+
|                                      Enterprise IAM Matrix                                         |
+-------------------------------+-----------------------------------+--------------------------------+
| Persona / Identity            | Assigned Role(s)                  | CEL Condition / Scope          |
+-------------------------------+-----------------------------------+--------------------------------+
| Legal & Compliance            | roles/bigquery.dataViewer         | Business Hours Only            |
| (gcp-legal-compliance)        | roles/cloudsql.viewer             | (08:00 - 18:00 UTC)            |
+-------------------------------+-----------------------------------+--------------------------------+
| Security Operations (SOC)     | roles/iam.securityReviewer        | Full Production                |
| (gcp-soc-secops)              | roles/logging.viewer              | Unconditional View             |
+-------------------------------+-----------------------------------+--------------------------------+
| Cloud Platform Team           | roles/resourcemanager             | Folder Admin on                |
| (gcp-platform-devops)         | .folderViewer                     | Non-Prod & Sandbox             |
+-------------------------------+-----------------------------------+--------------------------------+
| Emergency Break-Glass         | roles/resourcemanager             | Time-limited with              |
| (gcp-breakglass-admins)       | .folderAdmin                      | mandatory audit alert          |
+-------------------------------+-----------------------------------+--------------------------------+
| Data Scientists & AI Research | roles/aiplatform.user             | Business Hours Only            |
| (gcp-data-scientists)         | roles/bigquery.dataViewer         | (08:00 - 18:00 UTC)            |
|                               | roles/bigquery.jobUser            |                                |
|                               | roles/storage.objectViewer        |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Agent Platform Deployers      | roles/aiplatform.admin            | Impersonation restricted only  |
| (gcp-agent-deployers)         | roles/storage.objectAdmin         | to dedicated Agent Platform    |
|                               | roles/iam.serviceAccountUser      | Service Accounts (sa-agent-*)  |
+-------------------------------+-----------------------------------+--------------------------------+
| AI & Compliance Auditors      | roles/aiplatform.viewer           | Full Production Read-Only      |
| (gcp-ai-auditors)             | roles/logging.viewer              | Model & Evaluation Audit       |
|                               | roles/iam.securityReviewer        |                                |
|                               | roles/bigquery.dataViewer         |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Training         | roles/aiplatform                  | Workload-isolated execution:   |
| (sa-agent-training)           | .customCodeServiceAgent           | Storage write & BQ Read        |
|                               | roles/storage.objectAdmin         |                                |
|                               | roles/bigquery.dataViewer,jobUser |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Serving          | roles/aiplatform.serviceAgent     | Workload-isolated execution:   |
| (sa-agent-serving)            | roles/storage.objectViewer        | Model weight loading & Logging |
|                               | roles/logging.logWriter           |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Vector Search    | roles/aiplatform.user             | Workload-isolated execution:   |
| (sa-agent-vector-search)      | roles/storage.objectViewer        | Vector index retrieval & query |
|                               | roles/logging.logWriter           |                                |
+-------------------------------+-----------------------------------+--------------------------------+
```

---

## 2. Common Expression Language (CEL) Specifications

### Legal Team & Data Scientist Business Hours Restriction
```cel
request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18
```
- **Rationale:** Prevents off-hours bulk data scraping and mitigates credential misuse outside supervised operations. Enforces time-bound access on analytical datasets, Vertex AI resources, and model training buckets.

### Agent Deployer Service Account Impersonation Guardrail
```cel
resource.name.extract('/serviceAccounts/{sa}').startsWith('sa-agent-')
```
- **Rationale:** Prevents privilege escalation by ensuring MLOps and Agent Deployers can only act on behalf of dedicated AI workload service accounts (`sa-agent-*`), completely blocking unauthorized impersonation of Terraform or administrative accounts.

### Break-Glass Time Boundary
```cel
request.time < timestamp('2026-12-31T23:59:59Z')
```
- **Rationale:** Eliminates permanent elevated privileges; guarantees expiration.

---

## 3. Dedicated Workload Service Accounts Architecture

Each stage of the Agent Platform and AI lifecycle runs under an independent, dedicated Service Account adhering to the Principle of Least Privilege:

1. **`sa-agent-training`**: Dedicated to Custom Training Jobs, Hyperparameter Tuning, and Pipeline training steps. Granted `roles/aiplatform.customCodeServiceAgent`, `roles/storage.objectAdmin` on training data/output buckets, and `roles/bigquery.dataViewer` + `roles/bigquery.jobUser`.
2. **`sa-agent-serving`**: Dedicated to online inference endpoints and realtime prediction instances. Granted `roles/aiplatform.serviceAgent`, read-only access to model artifacts with `roles/storage.objectViewer`, and `roles/logging.logWriter` to trace inference logs.
3. **`sa-agent-vector-search`**: Dedicated to Vector Search indexing and similarity search retrievals (RAG). Granted `roles/aiplatform.user` and read-only storage permissions.
