# Módulo Terraform: Fábrica de Proyectos de Cargas de Trabajo de IA (`ai-workload-project`)

Módulo corporativo para aprovisionar y gobernar proyectos dedicados a Inteligencia Artificial, Vertex AI y plataformas de agentes generativos en Google Cloud, alineado con **NIST AI RMF 1.0**, **ISO/IEC 42001**, **RGPD (Art. 22, 25, 32)**, **PCI-DSS v4.0** y **HIPAA**.

---

## 🚀 Arquitectura y Componentes Integrados

El módulo estandariza el aprovisionamiento de un entorno de IA corporativo integrando de forma nativa:

1. **Project Factory & APIs Especializadas:**
   - Creación del proyecto en la carpeta designada (`folder_id`) y vinculación a cuenta de facturación.
   - Activación automática de APIs de Vertex AI (`aiplatform.googleapis.com`, `notebooks.googleapis.com`, `datacatalog.googleapis.com`), almacenamiento, KMS y contenedorización.
2. **Gobernanza de Datos y FinOps:**
   - Inyección homogénea de etiquetas de clasificación (`data_classification = confidential-pci-hipaa`), marco de cumplimiento, centro de costes y unidad de negocio.
3. **Cifrado CMEK Dedicado (`modules/cmek-kms`):**
   - Provisión de Cloud KMS KeyRing y CryptoKey con rotación automática cada 90 días.
   - Creación y autorización de identidades de servicio de Google (`storage`, `aiplatform`, `artifactregistry`, `bigquery`) para operaciones de cifrado/descifrado.
4. **Data Lake Seguro en Cloud Storage:**
   - Bucket con acceso uniforme a nivel de bucket (`uniform_bucket_level_access = true`), prevención de acceso público (`public_access_prevention = enforced`), versionado y cifrado CMEK por defecto.
   - Creación de estructuras base para datasets (`training-data/`) y artefactos de modelos (`models/`).
5. **Artifact Registry Seguro:**
   - Repositorio Docker cifrado con CMEK para imágenes de entrenamiento personalizado y servidores de inferencia.
6. **Recursos de Demostración y Experimentación de Vertex AI:**
   - Instancia de Vertex AI Tensorboard para trazabilidad y auditoría de experimentos ML.
   - Endpoint de predicción gestionado con cifrado CMEK.
7. **Integración con VPC Service Controls:**
   - Inscripción automática del proyecto dentro del perímetro de seguridad (`google_access_context_manager_service_perimeter_resource`).

---

## 📋 Uso de Ejemplo

```hcl
module "clinical_ai_project" {
  source = "../../modules/ai-workload-project"

  project_id      = "prj-prod-clinical-ai-01"
  project_name    = "Clinical Diagnostics AI Platform"
  folder_id       = "folders/123456789012"
  billing_account = "012345-678901-ABCDEF"
  primary_region  = "europe-west1"
  environment     = "prod"

  data_classification  = "confidential-pci-hipaa"
  cost_center          = "cc-clinical-ai"
  business_unit        = "digital-health"
  compliance_framework = "nist-ai-rmf-iso-42001-hipaa"

  service_perimeter_name = "accessPolicies/12345/servicePerimeters/sp_regulated_data_shield"
}
```

---

## 🔒 Entradas Principales (Inputs)

| Variable | Descripción | Tipo | Por Defecto |
| :--- | :--- | :--- | :--- |
| `project_id` | ID del proyecto GCP | `string` | n/a (Requerido) |
| `project_name` | Nombre para mostrar del proyecto | `string` | n/a (Requerido) |
| `folder_id` | ID de la carpeta contenedora en la jerarquía | `string` | n/a (Requerido) |
| `billing_account` | ID de la cuenta de facturación | `string` | n/a (Requerido) |
| `primary_region` | Región GCP principal (ej. `europe-west1`) | `string` | `"europe-west1"` |
| `environment` | Entorno de despliegue (`prod`, `stg`, `dev`) | `string` | `"prod"` |
| `create_cmek` | Si se debe aprovisionar CMEK dedicada | `bool` | `true` |
| `create_storage_bucket` | Si se debe crear el bucket de datos para IA | `bool` | `true` |
| `create_artifact_registry` | Si se debe crear el repositorio Docker en Artifact Registry | `bool` | `true` |
| `create_tensorboard` | Si se debe crear instancia de Vertex AI Tensorboard | `bool` | `true` |
| `create_endpoint` | Si se debe crear endpoint de inferencia Vertex AI | `bool` | `true` |
| `service_perimeter_name` | Nombre del perímetro VPC-SC para inscribir el proyecto | `string` | `""` |

---

## 📤 Salidas Principales (Outputs)

| Nombre | Descripción |
| :--- | :--- |
| `project_id` | ID del proyecto aprovisionado |
| `project_number` | Número del proyecto aprovisionado |
| `cmek_keyring_id` | ID del KeyRing de Cloud KMS creado |
| `cmek_crypto_key_id` | ID de la CryptoKey CMEK |
| `ai_data_bucket_name` | Nombre del bucket de Cloud Storage creado |
| `ai_data_bucket_url` | URI `gs://` del bucket de datos de IA |
| `artifact_registry_repository_id` | ID del repositorio Artifact Registry |
| `vertex_tensorboard_id` | ID de la instancia de Vertex AI Tensorboard |
| `vertex_endpoint_id` | ID del endpoint de Vertex AI |
