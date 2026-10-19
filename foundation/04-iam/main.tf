/**
 * Phase 04: IAM - Conditional & Principle of Least Privilege Access
 * Integrates Google Workspace/Cloud Identity provider, dedicated workload service accounts,
 * and role bindings with CEL conditions for Data Scientists, Agent Deployers, Auditors, Legal, SecOps, and Platform teams.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
    googleworkspace = {
      source  = "hashicorp/googleworkspace"
      version = ">= 0.7.0"
    }
  }
}

provider "googleworkspace" {
  customer_id             = var.customer_id
  impersonated_user_email = var.admin_user_email
  oauth_scopes = [
    "https://www.googleapis.com/auth/admin.directory.group",
    "https://www.googleapis.com/auth/admin.directory.group.member",
    "https://www.googleapis.com/auth/admin.directory.user.readonly"
  ]
}

# 1. Google Workspace Security Groups
resource "googleworkspace_group" "legal_compliance_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.legal_team_group
  name        = "GCP Legal and Compliance Audit Team"
  description = "Regulated group for legal audit with restricted time-based read access"
}

resource "googleworkspace_group" "soc_team_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.soc_team_group
  name        = "GCP Security Operations Center"
  description = "Security operations team for audit review and logging inspection"
}

resource "googleworkspace_group" "break_glass_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.break_glass_group
  name        = "GCP Emergency Break-Glass Admins"
  description = "Emergency administrative elevation group"
}

resource "googleworkspace_group" "data_scientists_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.data_scientists_group
  name        = "GCP Data Scientists & AI Researchers"
  description = "Data science team with time-bound access to Vertex AI training and analytical datasets"
}

resource "googleworkspace_group" "agent_deployers_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.agent_deployers_group
  name        = "GCP AI Agent Platform Deployers"
  description = "MLOps and Agent deployers with restricted service account impersonation guardrails"
}

resource "googleworkspace_group" "ai_auditors_group" {
  count       = var.manage_workspace_groups ? 1 : 0
  email       = var.ai_auditors_group
  name        = "GCP AI Governance & Compliance Auditors"
  description = "Independent audit team with read-only inspection access to AI models, metrics, and logs"
}

# 2. Dedicated Workload Service Accounts (Principle of Least Privilege per Workload)
locals {
  workload_service_accounts = {
    "sa-agent-training" = {
      display_name = "Agent Platform Training Workload Service Account"
      description  = "Dedicated SA for executing Vertex AI Custom Training and Hyperparameter Tuning jobs"
    }
    "sa-agent-serving" = {
      display_name = "Agent Platform Serving & Prediction Workload Service Account"
      description  = "Dedicated SA for hosting Vertex AI Inference Endpoints and Online Agent Serving"
    }
    "sa-agent-vector-search" = {
      display_name = "Agent Platform Vector Search & RAG Workload Service Account"
      description  = "Dedicated SA for Vector Search index querying and similarity retrieval"
    }
  }

  sa_training_email      = var.service_account_project_id != null ? google_service_account.workload_sa["sa-agent-training"].email : "sa-agent-training@bank-clinical-enterprise.iam.gserviceaccount.com"
  sa_serving_email       = var.service_account_project_id != null ? google_service_account.workload_sa["sa-agent-serving"].email : "sa-agent-serving@bank-clinical-enterprise.iam.gserviceaccount.com"
  sa_vector_search_email = var.service_account_project_id != null ? google_service_account.workload_sa["sa-agent-vector-search"].email : "sa-agent-vector-search@bank-clinical-enterprise.iam.gserviceaccount.com"
}

resource "google_service_account" "workload_sa" {
  for_each = var.service_account_project_id != null ? local.workload_service_accounts : {}

  account_id   = each.key
  display_name = each.value.display_name
  description  = each.value.description
  project      = var.service_account_project_id
}

# 3. Production Folder IAM with CEL Conditions
module "production_iam" {
  source = "../../modules/iam-conditional-binding"

  folder_id = var.prod_folder_id

  bindings = {
    # ---------------------------------------------------------
    # 1. Legal & Compliance Department
    # ---------------------------------------------------------
    "legal_bq_viewer" = {
      role   = "roles/bigquery.dataViewer"
      member = "group:${var.legal_team_group}"
      condition = {
        title       = "legal_business_hours_access"
        description = "Allows access only during European business hours (08:00 - 18:00 UTC) to prevent data exfiltration"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    "legal_sql_viewer" = {
      role   = "roles/cloudsql.viewer"
      member = "group:${var.legal_team_group}"
      condition = {
        title       = "legal_business_hours_access"
        description = "Allows access only during European business hours (08:00 - 18:00 UTC) to prevent data exfiltration"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    # ---------------------------------------------------------
    # 2. Security Operations Center (SOC)
    # ---------------------------------------------------------
    "soc_security_reviewer" = {
      role   = "roles/iam.securityReviewer"
      member = "group:${var.soc_team_group}"
    }

    "soc_logging_viewer" = {
      role   = "roles/logging.viewer"
      member = "group:${var.soc_team_group}"
    }

    # ---------------------------------------------------------
    # 3. Cloud Admin Break-Glass (Emergency Elevation)
    # ---------------------------------------------------------
    "admin_break_glass" = {
      role   = "roles/resourcemanager.folderAdmin"
      member = "group:${var.break_glass_group}"
      condition = {
        title       = "break_glass_temporary_expiring"
        description = "Time-limited emergency break-glass elevation"
        expression  = "request.time < timestamp('2026-12-31T23:59:59Z')"
      }
    }

    # ---------------------------------------------------------
    # 4. Data Scientists & AI Researchers (Supervised Business Hours)
    # ---------------------------------------------------------
    "data_scientist_vertex_user" = {
      role   = "roles/aiplatform.user"
      member = "group:${var.data_scientists_group}"
      condition = {
        title       = "data_scientist_business_hours_access"
        description = "Restricts Vertex AI user operations to European business hours (08:00 - 18:00 UTC)"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    "data_scientist_bq_viewer" = {
      role   = "roles/bigquery.dataViewer"
      member = "group:${var.data_scientists_group}"
      condition = {
        title       = "data_scientist_business_hours_access"
        description = "Restricts analytical dataset reading to European business hours (08:00 - 18:00 UTC)"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    "data_scientist_bq_job_user" = {
      role   = "roles/bigquery.jobUser"
      member = "group:${var.data_scientists_group}"
      condition = {
        title       = "data_scientist_business_hours_access"
        description = "Allows BigQuery query execution only during business hours"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    "data_scientist_storage_viewer" = {
      role   = "roles/storage.objectViewer"
      member = "group:${var.data_scientists_group}"
      condition = {
        title       = "data_scientist_business_hours_access"
        description = "Allows reading training datasets and artifacts only during business hours"
        expression  = "request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18"
      }
    }

    # ---------------------------------------------------------
    # 5. AI Agent Platform Deployers (MLOps)
    # ---------------------------------------------------------
    "agent_deployer_vertex_admin" = {
      role   = "roles/aiplatform.admin"
      member = "group:${var.agent_deployers_group}"
    }

    "agent_deployer_storage_admin" = {
      role   = "roles/storage.objectAdmin"
      member = "group:${var.agent_deployers_group}"
    }

    "agent_deployer_sa_user" = {
      role   = "roles/iam.serviceAccountUser"
      member = "group:${var.agent_deployers_group}"
      condition = {
        title       = "agent_deployer_sa_impersonation_guard"
        description = "Allows impersonating only dedicated Agent Platform workload service accounts (sa-agent-*)"
        expression  = "resource.name.extract('/serviceAccounts/{sa}').startsWith('sa-agent-')"
      }
    }

    # ---------------------------------------------------------
    # 6. AI & Compliance Auditors (Read-Only Inspection)
    # ---------------------------------------------------------
    "ai_auditor_vertex_viewer" = {
      role   = "roles/aiplatform.viewer"
      member = "group:${var.ai_auditors_group}"
    }

    "ai_auditor_logging_viewer" = {
      role   = "roles/logging.viewer"
      member = "group:${var.ai_auditors_group}"
    }

    "ai_auditor_security_reviewer" = {
      role   = "roles/iam.securityReviewer"
      member = "group:${var.ai_auditors_group}"
    }

    "ai_auditor_bq_viewer" = {
      role   = "roles/bigquery.dataViewer"
      member = "group:${var.ai_auditors_group}"
    }

    # ---------------------------------------------------------
    # 7. Dedicated Workload Service Accounts (Least Privilege)
    # ---------------------------------------------------------
    # Training Workload
    "sa_training_custom_code" = {
      role   = "roles/aiplatform.customCodeServiceAgent"
      member = "serviceAccount:${local.sa_training_email}"
    }

    "sa_training_storage_admin" = {
      role   = "roles/storage.objectAdmin"
      member = "serviceAccount:${local.sa_training_email}"
    }

    "sa_training_bq_viewer" = {
      role   = "roles/bigquery.dataViewer"
      member = "serviceAccount:${local.sa_training_email}"
    }

    "sa_training_bq_job_user" = {
      role   = "roles/bigquery.jobUser"
      member = "serviceAccount:${local.sa_training_email}"
    }

    # Serving / Inference Workload
    "sa_serving_service_agent" = {
      role   = "roles/aiplatform.serviceAgent"
      member = "serviceAccount:${local.sa_serving_email}"
    }

    "sa_serving_storage_viewer" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:${local.sa_serving_email}"
    }

    "sa_serving_logging_writer" = {
      role   = "roles/logging.logWriter"
      member = "serviceAccount:${local.sa_serving_email}"
    }

    # Vector Search / RAG Workload
    "sa_vector_search_user" = {
      role   = "roles/aiplatform.user"
      member = "serviceAccount:${local.sa_vector_search_email}"
    }

    "sa_vector_search_storage_viewer" = {
      role   = "roles/storage.objectViewer"
      member = "serviceAccount:${local.sa_vector_search_email}"
    }

    "sa_vector_search_logging_writer" = {
      role   = "roles/logging.logWriter"
      member = "serviceAccount:${local.sa_vector_search_email}"
    }
  }
}
