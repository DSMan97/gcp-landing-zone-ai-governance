# Matriz de Mapeo de Cumplimiento Técnico RGPD (GDPR)

> **⚠️ AVISO LEGAL Y DESCARGO DE RESPONSABILIDAD (DISCLAIMER):**
> Este documento y la arquitectura técnica de la Landing Zone descrita en este repositorio constituyen exclusivamente un **marco de referencia técnico, arquitectónico y de buenas prácticas de ingeniería de seguridad en la nube (Security and Privacy by Design & by Default)**. 
> 
> **No constituyen una certificación legal, regulatoria o formal del RGPD ni representan asesoramiento jurídico vinculante.** 
> La conformidad legal plena con el Reglamento General de Protección de Datos (UE) 2016/679 (RGPD / GDPR) requiere, además de los controles de infraestructura aquí implementados, la adopción de medidas organizativas, políticas de gobierno corporativo, Acuerdos de Encargo de Tratamiento (DPA), Evaluaciones de Impacto relativas a la Protección de Datos (EIPD / DPIA), y la validación por parte del Delegado de Protección de Datos (DPO) y auditores acreditados de la entidad financiera o sanitaria.

---

## 🏛️ Contexto y Alcance para Entidades Reguladas (Banca y Salud)

En entornos de **Banca y Datos Clínicos/Salud**, la protección de los datos personales y de categorías especiales (datos biométricos, de salud o financieros) exige que las medidas técnicas de seguridad sean **preventivas, verificables y continuas**.

Esta Landing Zone implementa un modelo de **Defensa en Profundidad** donde los controles técnicos de Google Cloud actúan como salvaguardas arquitectónicas para mitigar los riesgos identificados en el RGPD, tales como la exfiltración de datos, accesos no autorizados, transferencias internacionales no conformes y falta de trazabilidad.

---

## 📊 Matriz de Mapeo: Artículos del RGPD vs. Controles Técnicos de la Landing Zone

| Artículo RGPD (UE 2016/679) | Principio / Requisito Regulatorio | Controles Técnicos en la Landing Zone de GCP | Componente / Archivo de Implementación | Tipo de Control |
| :--- | :--- | :--- | :--- | :--- |
| **Art. 5(1)(a) & 5(1)(b)** | **Licitud, Lealtad y Limitación de la Finalidad:** Los datos deben ser tratados para fines determinados, explícitos y legítimos. | Segregación estricta de dominios bancarios y clínicos mediante jerarquía de carpetas organizacionales y proyectos aislados por entorno (`dev`, `stg`, `prod`), evitando el cruce accidental de información entre diferentes tratamientos. | `foundation/01-folders/main.tf`, `environments/prod/main.tf` | Preventivo / Organizacional |
| **Art. 5(1)(c)** | **Minimización de Datos:** Los datos deben ser adecuados, pertinentes y limitados a lo necesario. | Módulo de gobernanza de etiquetas obligatorias (`modules/data-governance-labels`) inyectando clasificación de datos (`confidential-pci-hipaa`), dominio y propietario. RBAC granular con mínimo privilegio por rol. | `modules/data-governance-labels/`, `foundation/04-iam/main.tf` | Gobernanza / Preventivo |
| **Art. 5(1)(e)** | **Limitación del Plazo de Conservación:** Conservación durante no más tiempo del necesario para los fines del tratamiento. | Retención inmutable de registros de auditoría en BigQuery configurada a 2555 días (7 años) para cumplimiento de normativas financieras; políticas de ciclo de vida (GCS Lifecycle rules) para caducidad y purga controlada de datos. | `foundation/05-logging/main.tf`, `foundation/07-ai-governance/main.tf` | Gobernanza / Detectivo |
| **Art. 5(1)(f)** | **Integridad y Confidencialidad:** Garantía de seguridad adecuada contra tratamiento ilícito, pérdida o daño accidental. | Cifrado CMEK obligatorio (KMS con rotación a 90 días y `prevent_destroy`), bloqueo de IPs externas (`compute.vmExternalIpAccess`), VPC Service Controls y denegación de acceso público a almacenamiento. | `foundation/02-org-policies/main.tf`, `foundation/03-custom-constraints/main.tf`, `environments/prod/main.tf` | Criptográfico / Preventivo |
| **Art. 5(2) & Art. 24** | **Responsabilidad Proactiva (Accountability):** Demostración continua del cumplimiento mediante medidas técnicas y organizativas. | Infraestructura como Código (IaC) inmutable y auditable con Terraform en CI/CD; autenticación sin claves estáticas mediante Workload Identity Federation (WIF) con trazabilidad de autoría en cada despliegue. | `bootstrap/main.tf`, `.github/workflows/`, `cloudbuild.yaml` | Gobernanza / Operacional |
| **Art. 25** | **Protección de Datos desde el Diseño y por Defecto (Privacy by Design & by Default):** Integración de salvaguardias en el diseño del sistema antes del tratamiento. | Guardrails preventivos a nivel de organización (`02-org-policies`), Custom Constraints CEL (`03-custom-constraints`) que bloquean la creación de recursos no conformes (ej. BigQuery sin CMEK o Vertex AI público) antes de su aprovisionamiento. | `foundation/02-org-policies/main.tf`, `foundation/03-custom-constraints/constraints/` | Preventivo (Shift-Left) |
| **Art. 28** | **Encargado del Tratamiento y Supervisión del Proveedor Cloud:** Supervisión y control transparente de los accesos realizados por el proveedor cloud. | **Access Approval** organizacional (`google_organization_access_approval_settings`) que exige aprobación previa justificada antes de accesos de soporte de Google; trazas de **Access Transparency** exportadas al log sink inmutable. | `foundation/00-organization/main.tf`, `foundation/05-logging/main.tf` | Preventivo / Supervisión |
| **Art. 30** | **Registro de las Actividades de Tratamiento (RAT):** Mantenimiento de inventario y trazabilidad de los sistemas que procesan datos personales. | Etiquetado homogéneo y metadatos de gobernanza (`data_classification`, `data_domain`, `data_owner`) aplicados en todos los recursos; inventario continuo mediante Cloud Asset Inventory y Security Command Center. | `modules/data-governance-labels/`, `foundation/00-organization/main.tf` | Gobernanza / Detectivo |
| **Art. 32(1)(a)** | **Seguridad del Tratamiento - Cifrado y Seudonimización:** Cifrado robusto en reposo y en tránsito de datos personales y sensibles. | Cifrado obligatorio con Customer-Managed Encryption Keys (CMEK) en Cloud KMS para BigQuery, Cloud Storage, Cloud SQL, Vertex AI y Artifact Registry. Cifrado en tránsito obligado mediante Private Service Connect (PSC) y Private Google Access. | `foundation/03-custom-constraints/`, `foundation/06-networking/main.tf`, `foundation/07-ai-governance/main.tf` | Criptográfico / Redes |
| **Art. 32(1)(b)** | **Seguridad del Tratamiento - Confidencialidad y Resiliencia:** Capacidad de garantizar confidencialidad, integridad y disponibilidad continua. | Perímetros de **VPC Service Controls** (`sp_prod_data_shield`) que impiden la exfiltración de datos; Hub-and-Spoke Shared VPC sin IPs públicas; protección contra destrucción accidental (`prevent_destroy = true`) en CMEK y datasets. | `modules/vpc-sc-perimeter/`, `foundation/06-networking/main.tf`, `environments/prod/main.tf` | Perimetral / Resiliencia |
| **Art. 32(1)(c)** | **Seguridad del Tratamiento - Disponibilidad y Restauración:** Capacidad de restaurar la disponibilidad y el acceso tras incidentes físicos o técnicos. | Versionado de objetos activado en buckets de datos de Cloud Storage; configuración de réplicas de alta disponibilidad y copias de seguridad continuas en Cloud SQL. | `foundation/07-ai-governance/main.tf`, `environments/prod/main.tf` | Resiliencia / Continuidad |
| **Art. 32(1)(d)** | **Seguridad del Tratamiento - Verificación y Evaluación Regular:** Evaluación periódica de la eficacia de las medidas técnicas de seguridad. | Security Command Center (SCC) organizacional con detección activa de amenazas y vulnerabilidades; auditoría exhaustiva de Data Access (`DATA_READ`, `DATA_WRITE`) en Vertex AI, BigQuery y Cloud Storage enrutada a BigQuery. | `foundation/00-organization/main.tf`, `foundation/05-logging/main.tf` | Detectivo / Auditoría |
| **Art. 33 & 34** | **Notificación de Brechas de Seguridad (Data Breach - 72h):** Detección temprana y comunicación oportuna de incidentes de seguridad. | Notificaciones automáticas de hallazgos `HIGH` y `CRITICAL` en Security Command Center vía Pub/Sub en streaming; contactos esenciales de seguridad (`google_essential_contacts_contact`); alertas de violaciones de perímetro VPC-SC. | `foundation/00-organization/main.tf`, `foundation/05-logging/main.tf` | Detectivo / Respuesta |
| **Art. 44 - 49** | **Residencia y Transferencias Internacionales de Datos:** Garantía de que los datos no se transfieren fuera del EEE sin las garantías requeridas. | Política organizacional `gcp.resourceLocations` que restringe el aprovisionamiento de recursos exclusivamente a regiones de la Unión Europea (`in:eu-locations`); KMS KeyRings, datasets y modelos alojados exclusivamente en zonas europeas (`europe-*`). | `foundation/02-org-policies/main.tf`, `environments/dev/main.tf`, `environments/stg/main.tf`, `environments/prod/main.tf` | Soberanía / Preventivo |
| **Art. 22 / IA** | **Decisiones Automatizadas y Gobernanza de Modelos / IA:** Salvaguardas específicas en el uso de IA y perfilado con datos personales. | Separación estricta de identidades para IA (`sa-agent-training`, `sa-agent-serving`, `sa-agent-vector-search`) con mínimo privilegio; guardrails en Vertex AI Workbench para impedir descarga local de datos personales; auditoría de inferencias. | `foundation/04-iam/main.tf`, `foundation/07-ai-governance/main.tf`, `docs/ai-governance.md` | Gobernanza IA / Mínimo Privilegio |

---

## 🛡️ Detalle de los Pilares Técnicos de Protección de Datos

### 1. Residencia y Soberanía de Datos (Art. 44 - 49 RGPD)
*   **Restricción Geográfica Estricta:** La política organizacional preventiva `gcp.resourceLocations` restringe de forma inviolable la creación de cualquier recurso informático, de almacenamiento o de procesamiento a la lista de ubicaciones de la Unión Europea (`in:eu-locations`).
*   **Aislamiento Regional de Claves Criptográficas:** Las claves de cifrado en Cloud KMS (`keyrings`) y los almacenes de datos residen en regiones explícitas de la UE (ej. `europe-west1`, `europe-west3`, `europe-southwest1`), garantizando que los datos cifrados no salgan del ámbito jurisdiccional europeo.

### 2. Seguridad del Tratamiento y Cifrado CMEK (Art. 32 RGPD)
*   **Cifrado Gestionado por el Cliente (CMEK):** A diferencia de las claves gestionadas por defecto por el proveedor, CMEK otorga a la entidad financiera o sanitaria el control soberano sobre las claves de cifrado, permitiendo revocar el acceso a los datos de forma instantánea (*crypto-shredding*) si fuera necesario.
*   **Rotación Criptográfica Automática:** Las claves maestras se rotan automáticamente cada 90 días (7.776.000 segundos) y cuentan con protección contra eliminación accidental (`prevent_destroy = true`).

### 3. Prevención de Exfiltración y Perímetros VPC-SC (Art. 5(1)(f) y Art. 32 RGPD)
*   **VPC Service Controls:** Crea una frontera criptográfica y de red alrededor de los servicios PaaS/SaaS de Google Cloud (BigQuery, Cloud Storage, Vertex AI, KMS, Secret Manager), impidiendo que identidades comprometidas o accesos no autorizados copien o extraigan datos sensibles hacia proyectos o buckets externos fuera del perímetro.
*   **Ciclo de Vida Multi-Entorno:** Operación en modo **Dry-Run** en entornos de desarrollo (`environments/dev`) para registrar telemetría y ajustar políticas sin fricciones, y modo **Enforced** estricto en producción (`environments/prod`).

### 4. Control de Acceso Granular y SoD con CEL (Art. 5(1)(f) y Art. 25 RGPD)
*   **Ventanas Laborales Restringidas:** Los perfiles de inspección legal y científicos de datos tienen su acceso a datos condicionado mediante expresiones CEL a horario laboral europeo (`08:00 - 18:00 UTC`), mitigando accesos fuera de jornada o fines de semana.
*   **Desacoplamiento de Cuentas de Servicio:** Cuentas dedicadas por función del ciclo de vida del agente (`sa-agent-training`, `sa-agent-serving`, `sa-agent-vector-search`) con prohibición de impersonación no autorizada mediante CEL bindings.

### 5. Supervisión del Proveedor Cloud: Access Approval y Access Transparency (Art. 28 RGPD)
*   **Supervisión Activa:** Cualquier intervención manual del personal de soporte o ingeniería de Google Cloud sobre los sistemas que albergan datos personales requiere una solicitud formal justificada que debe ser aprobada explícitamente por los administradores de seguridad de la entidad.
*   **Auditoría Forense Inmutable:** Todos los accesos se registran con firma criptográfica en el log sink centralizado de BigQuery con 7 años de retención inmutable.

---

## 🔍 Verificación y Auditoría Continua

Para auditar y validar de forma continua estos controles en los despliegues de infraestructura:
1.  **Validación Estática en CI/CD:** Ejecución de `terraform plan` y análisis de políticas con herramientas de Shift-Left.
2.  **Monitoreo en Tiempo Real:** Security Command Center (SCC) e ingesta en BigQuery de violaciones de VPC Service Controls e intentos de acceso no autorizados.
3.  **Inspección de Políticas Organizativas:** Verificación de las restricciones activas en `gcp-landing-zone/foundation/02-org-policies` y `foundation/03-custom-constraints`.
