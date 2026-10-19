# Modelo de Amenazas y Matriz de Mitigación de Riesgos

## 1. Visión General del Modelado de Amenazas (Metodología STRIDE)

| Categoría de Amenaza | Vector de Ataque | Contramedida en la Landing Zone | Mecanismo de Verificación |
| :--- | :--- | :--- | :--- |
| **Spoofing** (Suplantación) | Credenciales de CI/CD comprometidas / Claves estáticas de SA robadas / Impersonación de identidades de agentes | Tokens OIDC con Workload Identity Federation (WIF); política organizacional `iam.disableServiceAccountKeyCreation`; condiciones CEL restringiendo desplegadores a `sa-agent-*` | Cumplimiento automatizado de políticas; ausencia de claves JSON estáticas; evaluación de políticas IAM |
| **Tampering** (Manipulación) | Modificación no autorizada de estados, alteración de logs o envenenamiento de modelos/datasets | Dataset inmutable en BigQuery con retención bloqueada (2555 días); cifrado con Cloud KMS CMEK; versionado en GCS; escaneo de contenedores e inmutabilidad en Artifact Registry | Comprobación de integridad de logs de auditoría, control de acceso en BigQuery y auditoría de rotación de claves KMS |
| **Repudiation** (Repudio) | Acceso a datos no auditado o invocaciones no supervisadas de modelos de IA / RAG | `google_organization_iam_audit_config` con registro obligatorio de `DATA_READ` y `DATA_WRITE` para `aiplatform.googleapis.com`, `bigquery.googleapis.com` y `storage.googleapis.com` | Ingesta en tiempo real hacia SIEM desde el sink agregado en BigQuery (`ds_audit_compliance_logs`) |
| **Information Disclosure** (Fuga de Información) | Exfiltración de datos vía endpoints públicos, buckets de almacenamiento o Vector Search | VPC Service Controls (`sp_regulated_data_shield`), `compute.vmExternalIpAccess (Deny All)`, `sql.restrictPublicIp`, restricciones CEL forzando VPCs privadas y CMEK en Vertex AI | Salvaguardas preventivas CEL, métricas de violación y estado del perímetro VPC-SC |
| **Denial of Service** (Denegación de Servicio) | Aprovisionamiento fraudulento de recursos, minado de criptomonedas o agotamiento de cuotas por modelos descontrolados | Política organizacional `gcp.resourceLocations` (exclusivo UE), `compute.skipDefaultNetworkCreation`, cuotas y alertas de FinOps | Evaluación de políticas en `google_project_service` y monitores de facturación FinOps |
| **Elevation of Privilege** (Escalada de Privilegios) | Escalada permanente de privilegios de administrador o Prompt Injection alterando el comportamiento de agentes | IAM de Mínimo Privilegio con condiciones CEL acotadas en tiempo; cuenta de servicio `sa-agent-serving` estrictamente limitada (sin administración IAM ni derechos de descifrado KMS); aislamiento PSC | Escaneos automatizados periódicos de IAM, auditorías estáticas de políticas y Cloud Audit Logs |

---

## 2. Vectores de Amenaza en IA y Agentes Autónomos

| Categoría de Amenaza de IA | Vector de Ataque Específico | Contramedida en la Landing Zone | Módulo de Referencia |
| :--- | :--- | :--- | :--- |
| **Prompt Injection** (Directa e Indirecta) | Prompts adversarios en entradas de usuario o documentos RAG manipulados que alteran la ejecución del agente | Cuenta `sa-agent-serving` dedicada con alcance mínimo de solo lectura; ejecución de APIs restringida vía Private Service Connect y VPC interna; ausencia de rutas de escalada de privilegios | `foundation/04-iam`, `foundation/06-networking` |
| **Exfiltración de Modelos y Datos** | Robo de pesos del modelo, scraping de datasets de entrenamiento o fugas por endpoints sin cifrar | Perímetro VPC-SC restringiendo `aiplatform.googleapis.com`; restricciones personalizadas CEL exigiendo VPC privada y CMEK en todos los CustomJobs y Endpoints; bloqueo de descargas en Workbench | `foundation/02-org-policies`, `foundation/03-custom-constraints`, `foundation/06-networking`, `foundation/07-ai-governance` |
| **Violación de Residencia de Datos en la UE** | Entrenamiento o inferencia de modelos en jurisdicciones extranjeras vulnerando el RGPD o el EU AI Act | Política organizacional `gcp.resourceLocations` forzando `in:eu-locations` (`europe-west1`, `europe-west4`); KeyRings de Cloud KMS y buckets GCS estrictamente regionalizados en la UE | `foundation/02-org-policies`, `foundation/07-ai-governance` |
| **Acceso no Autorizado y Manipulación de Modelos** | Invocación ilegítima de inferencia o alteración de endpoints productivos | Separación de funciones (Científicos de Datos vs Desplegadores de Agentes vs Auditores de IA) con condiciones CEL; pista de auditoría para todas las predicciones y despliegues de artefactos | `foundation/04-iam`, `foundation/05-logging`, `docs/ai-governance.md` |

---

## 3. Impacto de la Mitigación de Riesgos

1. **Minimización del Radio de Impacto (*Blast Radius*):** La segmentación entre carpetas y proyectos dedicados previene el movimiento lateral entre sistemas transaccionales bancarios, analítica clínica y pipelines de modelos de IA.
2. **Resiliencia Determinista de Datos:** La pista de auditoría inmutable de 7 años garantiza la auditabilidad para inspecciones regulatorias bajo Basilea III, el requisito 10 de PCI-DSS, HIPAA §164.312(b) y el Artículo 12 del Reglamento de IA de la UE (EU AI Act).
3. **Gobernanza Soberana de IA y Confidencialidad:** La estricta residencia de datos en la UE (`europe-*`), la ejecución en VPC privada y la protección con CMEK previenen la exposición de modelos entre diferentes inquilinos y la exfiltración no autorizada de datos de entrenamiento.
4. **Ejecución Resiliente de Agentes:** Los límites endurecidos de identidad y las redes en defensa en profundidad evitan que los ataques de Prompt Injection comprometan la infraestructura cloud subyacente.
