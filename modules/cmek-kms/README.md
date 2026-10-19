# Módulo Terraform: CMEK Cloud KMS (`cmek-kms`)

Módulo reutilizable para la provisión y gobierno de claves de cifrado administradas por el cliente (**Customer-Managed Encryption Keys - CMEK**) en Google Cloud KMS, cumpliendo con los estándares de seguridad de **PCI-DSS v4.0**, **HIPAA**, **ISO 27001** y **RGPD (Art. 32)**.

---

## 🚀 Funcionalidades

1. **Gestión de Llaveros y Claves (KeyRing & CryptoKey):**
   - Provisión de KeyRings en regiones soberanas de Google Cloud.
   - Rotación automática de claves criptográficas configurable (por defecto cada 90 días / `7776000s`).
2. **Descubrimiento y Autorización de Service Agents:**
   - Creación automática de identidades de servicio de Google (`google_project_service_identity`) para servicios clave: Cloud Storage, Vertex AI, BigQuery, Artifact Registry, Pub/Sub, Compute Engine, etc.
   - Concesión automática del rol `roles/cloudkms.cryptoKeyEncrypterDecrypter` a los agentes de servicio e identidades adicionales requeridas.
3. **Etiquetado de Gobernanza:** Soporte de metadatos FinOps y clasificación de datos.

---

## 📋 Uso de Ejemplo

```hcl
module "ai_cmek" {
  source = "../../modules/cmek-kms"

  project_id   = "prj-prod-ai-core"
  location     = "europe-west1"
  keyring_name = "kr-ai-governance-europe-west1"
  key_name     = "key-ai-governance-cmek"

  service_identities = [
    "storage.googleapis.com",
    "aiplatform.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com"
  ]

  labels = {
    data_classification = "confidential-pci-hipaa"
    managed_by          = "terraform"
  }
}
```

---

## 🔒 Entradas (Inputs)

| Nombre | Descripción | Tipo | Por Defecto | Requerido |
| :--- | :--- | :--- | :--- | :--- |
| `project_id` | ID del proyecto GCP donde reside el KeyRing y CryptoKey | `string` | n/a | **Sí** |
| `location` | Ubicación o región de GCP (ej. `europe-west1`) | `string` | n/a | **Sí** |
| `keyring_name` | Nombre del Cloud KMS KeyRing | `string` | n/a | **Sí** |
| `key_name` | Nombre de la CryptoKey CMEK | `string` | n/a | **Sí** |
| `rotation_period` | Periodo de rotación automática (ej. `7776000s` para 90 días) | `string` | `"7776000s"` | No |
| `purpose` | Propósito de la clave KMS | `string` | `"ENCRYPT_DECRYPT"` | No |
| `service_identities` | Lista de servicios GCP para generar Service Identity y otorgar permisos de cifrado/descifrado | `list(string)` | `[]` | No |
| `encrypter_decrypter_members` | Miembros IAM adicionales con rol EncrypterDecrypter | `list(string)` | `[]` | No |
| `labels` | Mapa de etiquetas para la CryptoKey | `map(string)` | `{}` | No |

---

## 📤 Salidas (Outputs)

| Nombre | Descripción |
| :--- | :--- |
| `key_ring_id` | ID completo del KMS KeyRing |
| `key_ring_name` | Nombre del KMS KeyRing |
| `crypto_key_id` | ID completo de la CryptoKey CMEK |
| `crypto_key_name` | Nombre de la CryptoKey CMEK |
| `service_agents` | Mapa con los correos de las identidades de servicio generadas |
