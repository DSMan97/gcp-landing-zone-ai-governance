/**
 * Phase 06: Networking - Shared VPC Hub, Private Service Connect & VPC-SC Perimeter
 * Configures Shared VPC Host, segregated subnets, Private Google Access, PSC for Google APIs,
 * Cloud Router/NAT, zero-trust firewall rules, and VPC Service Controls security perimeter.
 */

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

provider "google" {
  project = var.network_host_project_id
  region  = var.primary_region
}

# 1. Shared VPC Network
resource "google_compute_network" "shared_vpc" {
  name                    = "vpc-shared-prod"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  project                 = var.network_host_project_id
  description             = "Centralized Shared VPC for Banking, Clinical, and AI production workloads."
}

# Enable Shared VPC Host Project
resource "google_compute_shared_vpc_host_project" "host" {
  project = var.network_host_project_id
}

# 2. Segregated Production Subnets with Private Google Access
resource "google_compute_subnetwork" "sb_banking_prod" {
  name                     = "sb-banking-prod-${var.primary_region}"
  ip_cidr_range            = "10.10.10.0/24"
  region                   = var.primary_region
  network                  = google_compute_network.shared_vpc.id
  private_ip_google_access = true
  project                  = var.network_host_project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0 # 100% sampling for banking compliance
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_subnetwork" "sb_clinical_prod" {
  name                     = "sb-clinical-prod-${var.primary_region}"
  ip_cidr_range            = "10.20.10.0/24"
  region                   = var.primary_region
  network                  = google_compute_network.shared_vpc.id
  private_ip_google_access = true
  project                  = var.network_host_project_id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1.0 # 100% sampling for HIPAA/GDPR clinical data
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

# 3. Private Service Connect (PSC) for Google APIs
# Global Internal IP address for PSC endpoint
resource "google_compute_global_address" "psc_google_apis" {
  name         = "ga-psc-google-apis"
  project      = var.network_host_project_id
  address_type = "INTERNAL"
  purpose      = "PRIVATE_SERVICE_CONNECT"
  network      = google_compute_network.shared_vpc.id
  address      = var.psc_endpoint_ip
}

# Global Forwarding Rule targeting all Google Cloud APIs and VPC-SC supported services
resource "google_compute_global_forwarding_rule" "psc_google_apis" {
  name                  = "fwd-psc-google-apis"
  project               = var.network_host_project_id
  target                = "all-apis"
  network               = google_compute_network.shared_vpc.id
  ip_address            = google_compute_global_address.psc_google_apis.id
  load_balancing_scheme = ""
}

# Cloud DNS Private Zones for routing API traffic to Private Service Connect
resource "google_dns_managed_zone" "googleapis_private_zone" {
  name        = "zone-googleapis-private"
  dns_name    = "googleapis.com."
  description = "Private DNS zone routing *.googleapis.com traffic through Private Service Connect"
  project     = var.network_host_project_id
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.shared_vpc.id
    }
  }
}

resource "google_dns_record_set" "psc_a_record" {
  name         = "psc.googleapis.com."
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.googleapis_private_zone.name
  project      = var.network_host_project_id
  rrdatas      = [google_compute_global_address.psc_google_apis.address]
}

resource "google_dns_record_set" "psc_cname_record" {
  name         = "*.googleapis.com."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.googleapis_private_zone.name
  project      = var.network_host_project_id
  rrdatas      = ["psc.googleapis.com."]
}

resource "google_dns_managed_zone" "pkg_dev_private_zone" {
  name        = "zone-pkg-dev-private"
  dns_name    = "pkg.dev."
  description = "Private DNS zone routing *.pkg.dev through Private Service Connect"
  project     = var.network_host_project_id
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.shared_vpc.id
    }
  }
}

resource "google_dns_record_set" "pkg_dev_cname" {
  name         = "*.pkg.dev."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.pkg_dev_private_zone.name
  project      = var.network_host_project_id
  rrdatas      = ["psc.googleapis.com."]
}

resource "google_dns_managed_zone" "gcr_io_private_zone" {
  name        = "zone-gcr-io-private"
  dns_name    = "gcr.io."
  description = "Private DNS zone routing *.gcr.io through Private Service Connect"
  project     = var.network_host_project_id
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.shared_vpc.id
    }
  }
}

resource "google_dns_record_set" "gcr_io_cname" {
  name         = "*.gcr.io."
  type         = "CNAME"
  ttl          = 300
  managed_zone = google_dns_managed_zone.gcr_io_private_zone.name
  project      = var.network_host_project_id
  rrdatas      = ["psc.googleapis.com."]
}

# 4. Cloud Router & Cloud NAT (No Public IPs on VMs)
resource "google_compute_router" "router" {
  name    = "cr-shared-prod-${var.primary_region}"
  region  = var.primary_region
  network = google_compute_network.shared_vpc.id
  project = var.network_host_project_id
}

resource "google_compute_router_nat" "nat" {
  name                               = "nat-shared-prod-${var.primary_region}"
  router                             = google_compute_router.router.name
  region                             = var.primary_region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  project                            = var.network_host_project_id

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}

# 5. Zero-Trust Firewall Rules
# Allow IAP for Secure Bastionless Management (TCP 22 SSH, TCP 3389 RDP)
resource "google_compute_firewall" "allow_iap" {
  name      = "fw-allow-iap-admin"
  network   = google_compute_network.shared_vpc.name
  project   = var.network_host_project_id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["35.235.240.0/20"] # Google Cloud IAP IP range
  target_tags   = ["iap-managed"]
}

# Allow Egress to PSC and Private Google Access endpoints (HTTPS 443)
resource "google_compute_firewall" "allow_google_apis_egress" {
  name      = "fw-allow-google-apis-egress"
  network   = google_compute_network.shared_vpc.name
  project   = var.network_host_project_id
  direction = "EGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  destination_ranges = [
    "${var.psc_endpoint_ip}/32", # PSC Endpoint
    "199.36.153.4/30",           # restricted.googleapis.com
    "199.36.153.8/30"            # private.googleapis.com
  ]
}

# Allow Internal Mesh between Banking and Clinical subnets for specific service ports
resource "google_compute_firewall" "allow_internal_mesh" {
  name      = "fw-allow-internal-mesh"
  network   = google_compute_network.shared_vpc.name
  project   = var.network_host_project_id
  direction = "INGRESS"
  priority  = 2000

  allow {
    protocol = "tcp"
    ports    = ["443", "8443", "3306", "5432"]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = ["10.10.10.0/24", "10.20.10.0/24"]
}

# Default Deny All Egress (Prevent unauthorized data exfiltration)
resource "google_compute_firewall" "deny_all_egress" {
  name      = "fw-deny-all-egress-default"
  network   = google_compute_network.shared_vpc.name
  project   = var.network_host_project_id
  direction = "EGRESS"
  priority  = 65534

  deny {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

# 6. VPC Service Controls (Access Context Manager & Service Perimeter Module)
resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.organization_id}"
  title  = var.access_policy_title
}

resource "google_access_context_manager_access_level" "hq_trusted_network" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/al_hq_trusted_network"
  title  = "al_hq_trusted_network"

  basic {
    conditions {
      ip_subnetworks = var.trusted_ingress_ip_ranges
    }
  }
}

module "service_perimeter" {
  source = "../../modules/vpc-sc-perimeter"

  policy         = google_access_context_manager_access_policy.policy.name
  perimeter_name = var.service_perimeter_name
  title          = var.service_perimeter_name
  dry_run        = false

  restricted_services = var.restricted_services

  resources = distinct(concat(
    ["projects/${var.network_host_project_id}"],
    var.protected_projects
  ))

  access_levels = [
    google_access_context_manager_access_level.hq_trusted_network.name
  ]

  ingress_policies = concat(
    [
      {
        from = {
          identity_type = "ANY_IDENTITY"
          sources = [
            {
              access_level = google_access_context_manager_access_level.hq_trusted_network.name
            }
          ]
        }
        to = {
          resources = ["*"]
          operations = [
            {
              service_name = "*"
            }
          ]
        }
      }
    ],
    length(var.authorized_ingress_identities) > 0 ? [
      {
        from = {
          identities = var.authorized_ingress_identities
          sources = [
            {
              access_level = "*"
            }
          ]
        }
        to = {
          resources = ["*"]
          operations = [
            {
              service_name = "*"
            }
          ]
        }
      }
    ] : []
  )
}
