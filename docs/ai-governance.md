# AI Governance Framework: Risks, Guardrails & Compliance

Este documento define el marco de gobernanza, gestión de riesgos y controles técnicos aplicados a las cargas de trabajo de Inteligencia Artificial (IA), Machine Learning (ML) y Agentes Autónomos desplegados sobre Google Cloud (Vertex AI, Agent Platform, BigQuery ML) en la Landing Zone, en conformidad con **NIST AI RMF 1.0**, **ISO/IEC 42001**, **EU AI Act**, **GDPR**, **PCI-DSS v4.0** y **HIPAA**.

---

## 1. Principales Vectores de Riesgo en Cargas de Trabajo de IA

```
                              ┌──────────────────────────────────────────────┐
                              │            Perímetro VPC-SC                  │
  [Usuario / Atacante]        │  ┌──────────────────┐  ┌──────────────────┐  │
          │                   │  │ Vertex AI Models │  │  Vector Search   │  │
   Prompt Injection           │  │   & Endpoints    │  │   (Embeddings)   │  │
          ▼                   │  └────────▲─────────┘  └────────▲─────────┘  │
  ┌───────────────┐           │           │                     │            │
  │ Agent Gateway │───────────┼───────────┼─────────────────────┘            │
  │   (Serving)   │           │           ▼                                  │
  └───────────────┘           │  ┌──────────────────┐                        │
          │                   │  │ CMEK Data Lake   │                        │
  Exfiltración de Datos (RAG) │  │  (Cloud Storage) │                        │
          ▼                   │  └──────────────────┘                        │
   [Bloqueado por VPC-SC]     └──────────────────────────────────────────────┘
```

### 1.1 Exfiltración de Datos (Data Exfiltration)
- **Descripción del Riesgo:** Fuga de datos sensibles (datos clínicos de pacientes, registros de tarjetas de pago PCI o propiedad intelectual) a través de canales no autorizados durante el entrenamiento, inferencia, pipelines de RAG (Retrieval-Augmented Generation) o exportación inadvertida de datasets.
- **Impacto:** Violación de GDPR (sanciones regulatorias), brechas de confidencialidad médica (HIPAA) y compromiso de datos financieros (PCI-DSS).

### 1.2 Residencia de Datos en la Unión Europea (EU Residency & Sovereignty)
- **Descripción del Riesgo:** Procesamiento o almacenamiento de datos de entrenamiento, embeddings, logs de inferencia o pesos de modelos en regiones fuera del Espacio Económico Europeo (EEE), vulnerando las cláusulas de transferencia internacional de datos.
- **Impacto:** Incumplimiento del Reglamento General de Protección de Datos (GDPR Art. 44-49) y de los requerimientos de soberanía digital del **EU AI Act**.

### 1.3 Inyección de Prompts (Prompt Injection - Directa e Indirecta)
- **Descripción del Riesgo:** Manipulación de las instrucciones del modelo mediante entradas maliciosas del usuario (inyección directa / *jailbreaking*) o a través de documentos y datos no confiables ingeridos dinámicamente por agentes en pipelines RAG (inyección indirecta), alterando el comportamiento del agente o forzando la ejecución de acciones no autorizadas.
- **Impacto:** Evasión de controles de seguridad, ejecución de llamadas a APIs no deseadas, fuga de contexto del sistema (*system prompt leakage*) y generación de respuestas no alineadas.

### 1.4 Acceso no Autorizado y Modificación de Modelos (Model Access & Integrity)
- **Descripción del Riesgo:** Acceso ilegítimo a endpoints de inferencia, modificación no autorizada de modelos en producción (*model poisoning* o manipulación de pesos), impersonación de identidades de servicio de agentes y despliegue de artefactos no verificados.
- **Impacto:** Alteración de decisiones críticas en scoring bancario o diagnóstico clínico, y pérdida de propiedad intelectual.

---

## 2. Matriz de Controles Técnicos Implementados

| Dominio de Seguridad | Riesgo Mitigado | Control Técnico en Landing Zone | Módulo / Fase Terraform |
| :--- | :--- | :--- | :--- |
| **Aislamiento de Perímetro** | Exfiltración de datos | **VPC Service Controls** (`sp_regulated_data_shield`) que bloquea transferencias de datos entre proyectos fuera del perímetro para `aiplatform.googleapis.com`, `storage.googleapis.com` y `bigquery.googleapis.com`. | `foundation/06-networking`, `foundation/07-ai-governance`, `environments/prod` |
| **Conectividad Privada** | Exfiltración de datos & Tránsito por Internet | **Private Service Connect (PSC)** y **Private Google Access (PGA)** con zonas DNS privadas (`*.googleapis.com`, `*.pkg.dev`), eliminando salidas a Internet público para llamadas a APIs de IA. | `foundation/06-networking` |
| **Políticas Organizacionales Preventivas** | Residencia en la UE | Org Policy `gcp.resourceLocations` configurada estrictamente con `in:eu-locations` (restringiendo despliegues a regiones `europe-*`). | `foundation/02-org-policies` |
| **Restricciones de Workbench** | Exfiltración y ejecución no autorizada | Org Policies de AI Notebooks: `ainotebooks.restrictPublicIp`, `ainotebooks.restrictRootAccess`, `ainotebooks.disableFileDownloads`, `ainotebooks.accessMode = ["SERVICE_ACCOUNT", "single-user"]`. | `foundation/02-org-policies` |
| **Custom Constraints (CEL)** | Exfiltración & Falta de Cifrado | Restricciones organizacionales YAML con CEL que exigen **CMEK** y **redes VPC privadas** en: `CustomJob`, `HyperparameterTuningJob`, `Endpoint`, `Index` y `IndexEndpoint`. | `foundation/03-custom-constraints` |
| **Gestión Criptográfica** | Compromiso de datos en reposo | **Cloud KMS CMEK** (`key-ai-governance-cmek`) con rotación automática a 90 días (7776000s) y `prevent_destroy` para buckets GCS, Vector Search, Artifact Registry y Endpoints de Vertex AI. | `foundation/07-ai-governance` |
| **Segregación de Identidades (IAM)** | Acceso no autorizado & Abuso de privilegios | Cuentas de servicio dedicadas (`sa-agent-training`, `sa-agent-serving`, `sa-agent-vector-search`) y separación de roles para científicos de datos, desplegadores y auditores con condiciones CEL de mínimo privilegio e impersonación controlada. | `foundation/04-iam` |
| **Mitigación de Prompt Injection** | Manipulación de Agentes / Prompt Injection | Separación estricta de privilegios de API en `sa-agent-serving` (solo lectura de GCS y escritura de logs; sin permisos de administración de IAM ni acceso a claves KMS); aislamiento de contexto en Vector Search. | `foundation/04-iam`, `foundation/07-ai-governance` |
| **Trazabilidad y Auditoría** | Repudio e Incidentes de Seguridad | **Audit Logs de Data Access** (`DATA_READ`, `DATA_WRITE`, `ADMIN_READ`) activados a nivel de organización para `aiplatform.googleapis.com` exportados a BigQuery (`ds_audit_compliance_logs`) con retención de 7 años. | `foundation/05-logging` |

---

## 3. Detalle de Controles por Categoría

### 3.1 Prevención de Exfiltración de Datos
1. **Perímetro VPC-SC Restrictivo:** Toda la suite de APIs de Vertex AI (`aiplatform.googleapis.com`), Cloud Storage (`storage.googleapis.com`), BigQuery (`bigquery.googleapis.com`), Artifact Registry y Cloud KMS residen dentro del perímetro `sp_regulated_data_shield`. Ningún dato procesado por modelos o agentes puede ser extraído hacia recursos o cuentas fuera de la organización autorizada.
2. **Forzado de Red Privada:** Las restricciones personalizadas CEL impiden la creación de endpoints de inferencia o índices de Vector Search que expongan IPs públicas o carezcan del parámetro de red VPC autorizada (`jobSpec.network` y `network`).
3. **Restricción de Descargas en Notebooks:** La política `ainotebooks.disableFileDownloads` bloquea la descarga de datasets clínicos y bancarios desde entornos Vertex AI Workbench hacia máquinas locales de los desarrolladores.

### 3.2 Residencia de Datos y Soberanía en la UE
1. **Regiones Europeas Homologadas:** La Landing Zone aplica la política organizacional `gcp.resourceLocations` admitiendo únicamente `in:eu-locations`. Las cargas de trabajo de IA se provisionan prioritariamente en `europe-west1` (Bélgica) y `europe-west4` (Países Bajos).
2. **Almacenamiento Criptográfico Regional:** Los KeyRings de Cloud KMS (`kr-ai-governance-europe-west1`), los buckets de datos y los repositorios de Artifact Registry se encuentran estrictamente regionalizados dentro de la UE, garantizando que el procesamiento y el material de clave nunca abandonen la jurisdicción comunitaria.
3. **Dataset de Auditoría en la UE:** El dataset centralizado de logs `ds_audit_compliance_logs` está ubicado en la multirregión `EU`.

### 3.3 Mitigación de Inyección de Prompts
1. **Defensa en Profundidad:** La arquitectura asume que el modelo puede recibir prompts adversarios. Por ende, la seguridad no depende únicamente de la alineación del modelo, sino de guardrails de infraestructura:
   - **Principio de Mínimo Privilegio del Agente:** La cuenta `sa-agent-serving` no posee privilegios para listar buckets ajenos, modificar esquemas de datos ni alterar políticas IAM.
   - **Restricción de Acceso a Herramientas (Tool Calling):** Los endpoints de servicio están segmentados en subredes aisladas y sólo pueden invocar APIs internas autorizadas a través de Private Service Connect.
2. **Monitoreo y Detección de Anomalías:** Trazabilidad de todas las llamadas a la API de predicción registradas en Cloud Audit Logs, permitiendo a los equipos de SOC y Compliance detectar patrones de ataque de inyección o extracción sistemática de datos.

### 3.4 Control de Acceso y Gobierno de Modelos
1. **Separación de Responsabilidades (SoD):**
   - **Científicos de Datos:** Permisos de experimentación (`roles/aiplatform.user`, `roles/bigquery.dataViewer`) sujetos a ventanas horarias laborales europeas (08:00 - 18:00 UTC) mediante expresiones CEL.
   - **Desplegadores de Agentes:** Permisos de despliegue (`roles/aiplatform.admin`) restringidos por condición CEL para impersonar exclusivamente cuentas de servicio con prefijo `sa-agent-*`.
   - **Auditores de IA:** Acceso exclusivo de solo lectura (`roles/aiplatform.viewer`, `roles/logging.viewer`) para inspección de métricas de sesgo, explicabilidad y trazabilidad en Tensorboard y Model Registry.
2. **Integridad de Artefactos de Modelos:** Los contenedores de inferencia se almacenan en Artifact Registry cifrado con CMEK, con políticas de inmutabilidad y escaneo de vulnerabilidades.

---

## 4. Alineación con Estándares y Marcos Regulatorios

### 4.1 NIST AI Risk Management Framework (AI RMF 1.0)
- **GOVERN:** Asignación estructurada de roles IAM por tipo de perfil de IA, directivas de cumplimiento corporativo y registro centralizado de excepciones.
- **MAP:** Identificación de activos de IA, clasificación de datos confidenciales y delimitación de superficies de ataque en `docs/threat-model.md`.
- **MEASURE:** Seguimiento de experimentos mediante Vertex AI Tensorboard y auditoría de accesos a datos con retención de 7 años.
- **MANAGE:** Aplicación automatizada de guardrails mediante Terraform, VPC Service Controls y Custom Constraints CEL.

### 4.2 ISO/IEC 42001 (Sistema de Gestión de Inteligencia Artificial)
- **Control A.6 (Evaluación de Impacto y Riesgos de IA):** Implementación de perímetros VPC-SC y CMEK para mitigar riesgos sobre la privacidad y seguridad de los datos.
- **Control A.8 (Ciclo de Vida de los Sistemas de IA):** Plantilla estandarizada de proyectos (`07-ai-governance`) con segregación de fases (datos de entrenamiento, registro de modelos y endpoints productivos).
- **Control A.9 (Gestión de Datos para IA):** Reglas para forzar acceso uniforme a nivel de bucket (`storage.uniformBucketLevelAccess`) y retención inmutable de registros.

### 4.3 Reglamento de Inteligencia Artificial de la UE (EU AI Act)
- **Sistemas de Alto Riesgo:** Aplicable a modelos analíticos de scoring financiero y diagnóstico clínico:
  - Trazabilidad y registro continuo de operaciones (`DATA_READ` / `DATA_WRITE` en Cloud Logging).
  - Robustez técnica, ciberseguridad y prevención de accesos no autorizados mediante VPC-SC y CMEK.
  - Almacenamiento y procesamiento garantizados en regiones de la Unión Europea.
