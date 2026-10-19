/**
 * Phase: Bootstrap - Backend Configuration
 * Remote backend for storing Terraform state securely.
 */

terraform {
  backend "gcs" {
    bucket = "bkt-tfstate-bootstrap-012345678901"
    prefix = "terraform/state/bootstrap"
  }
}
