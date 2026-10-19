# Arquitectura de la Landing Zone Empresarial - Banca y Datos Clínicos

## 1. Resumen Ejecutivo y Objetivo

Esta Landing Zone está diseñada para maximizar la seguridad, el cumplimiento normativo y la confiabilidad operativa para organizaciones que gestionan conjuntos de datos altamente sensibles bajo los estándares **PCI-DSS**, **HIPAA**, **RGPD (GDPR)** e **ISO 27001**.

Mediante la aplicación de salvaguardas declarativas a nivel de la Organización de GCP, la plataforma mitiga riesgos operativos, previene la exfiltración de datos, garantiza la trazabilidad completa y optimiza la gestión FinOps.

---

## 2. Jerarquía Estructural

```
Organización (organizations/123456789012)
├── fldr-common
│   ├── fldr-bootstrap (Buckets de estado, KMS CMEK, CI/CD WIF)
│   ├── fldr-security-governance (Sinks de auditoría, Políticas de acceso)
│   └── fldr-networking-hub (Proyecto Host de Shared VPC)
├── fldr-production
│   ├── fldr-banking-prod (APIs de Core Banking y SQL transaccional)
│   └── fldr-clinical-prod (Data Lake clínico y analítica en BigQuery)
├── fldr-non-production
│   ├── fldr-banking-non-prod (Desarrollo y QA)
│   ├── fldr-clinical-non-prod (Entrenamiento de modelos y desarrollo analítico)
│   ├── fldr-banking-stg (Staging e integración pre-productiva)
│   └── fldr-clinical-stg (Data Lake de staging)
└── fldr-sandbox (Entorno aislado de experimentación con datos no sensibles)
```

---

## 3. Pilares Arquitectónicos Principales

### 3.1 Topología de Red (Shared VPC Hub-and-Spoke)
- Proyecto Host de red centralizado (`prj-net-shared-hub`).
- Subredes segregadas: `sb-banking-prod` (10.10.10.0/24) y `sb-clinical-prod` (10.20.10.0/24).
- Private Google Access (PGA) y Private Service Connect (PSC) para APIs de Google (`10.100.100.100`) mediante zonas privadas de Cloud DNS (`*.googleapis.com`, `*.pkg.dev`, `*.gcr.io`) sin tránsito por Internet.
- Egress restringido por defecto (`deny_all_egress`) con reglas granulares de autorización de salida para endpoints de APIs de Google / PSC, Cloud NAT y bastiones IAP.

### 3.2 Gobernanza Criptográfica (CMEK)
- Claves de cifrado administradas por el cliente (Cloud KMS Customer-Managed Encryption Keys) rotadas automáticamente cada 90 días (`7776000s`).
- Protección contra destrucción habilitada en todas las claves primarias en producción (`prevent_destroy = true`).
- Obligatoriedad forzada en todos los datasets de BigQuery y buckets de Cloud Storage mediante restricciones CEL personalizadas.

### 3.3 Perímetro de Seguridad (VPC Service Controls) y Diferenciación de Entornos
- **Módulo de Perímetro Reutilizable (`modules/vpc-sc-perimeter`):** Estandariza la parametrización de perímetros regulares y de puente (bridge), transiciones dry-run/enforced, catálogos de servicios restringidos, políticas de ingreso/egreso y niveles de acceso.
- **Producción (`environments/prod`):** Modo estrictamente **Enforced** (`status`) en `sp_regulated_data_shield` abarcando todos los servicios soportados (`aiplatform`, `bigquery`, `storage`, `sqladmin`, `cloudkms`, `secretmanager`, `notebooks`, `container`, `artifactregistry`), bloqueando cualquier intento de exfiltración de datos.
- **Staging (`environments/stg`):** Perímetro de validación pre-productiva (`sp_stg_data_shield`) con validación de claves CMEK para probar integraciones y paridad antes de la promoción a producción.
- **Desarrollo (`environments/dev`):** Modo **Dry-Run** (`use_explicit_dry_run_spec = true`) en `sp_dev_data_shield`, registrando telemetría de violaciones en Cloud Logging sin interrumpir la velocidad de desarrollo ni los pipelines de experimentación.

### 3.4 Capa de Seguridad Transversal (SCC y Access Transparency)
- **Alertas organizacionales de Security Command Center (SCC):** Transmisión de notificaciones de hallazgos en tiempo real a Pub/Sub para amenazas activas de severidad `HIGH` y `CRITICAL`, detecciones de vulnerabilidades y anomalías de cumplimiento, junto con reglas de silenciamiento (mute rules) a nivel org para reducción del ruido operativo.
- **Access Approval y Access Transparency:** Flujo de aprobación obligatorio y auditabilidad para cualquier acceso administrativo de Google Cloud a datos y cargas de trabajo corporativas en todos los servicios, transmitiendo registros inmutables `cloudaudit.googleapis.com/access_transparency` al sink de cumplimiento centralizado en BigQuery.

### 3.5 Gobernanza de IA y Plantilla de Cargas de Trabajo Seguras
- Fábrica de proyectos modular y reutilizable (`modules/ai-workload-project`) y módulo dedicado de CMEK (`modules/cmek-kms`) para el aprovisionamiento rápido y conforme de cargas de trabajo de IA en diversas unidades de negocio.
- Proyecto plantilla dedicado a IA (`07-ai-governance`) inscrito en el perímetro de VPC Service Controls.
- APIs preactivadas para Vertex AI, Workbench Notebooks, Artifact Registry, Cloud Storage y BigQuery.
- Cifrado CMEK forzado en el data lake de Cloud Storage, repositorios Docker de Artifact Registry, Tensorboards de Vertex AI y Endpoints de inferencia con rotación automática cada 90 días.
- Acceso uniforme a nivel de bucket, prevención de acceso público y directorios estructurados para el ciclo de vida de IA (`training-data/`, `models/`).

### 3.6 CI/CD sin Claves Estáticas (Keyless)
- Autenticación en GitHub Actions mediante tokens OIDC con Workload Identity Federation (WIF).
- Cero claves JSON estáticas de larga duración almacenadas en repositorios.

---

## 4. Alineación con Arquitecturas de Referencia y Decisiones de Diseño

Esta arquitectura se fundamenta en las guías y blueprints empresariales oficiales de Google Cloud, incorporando guardrails especializados para IA y cargas de trabajo reguladas:

### 4.1 Fundamentos y Estándares de la Industria Adoptados
- **Google Cloud Landing Zone Design Guide** ([cloud.google.com/architecture/landing-zones](https://cloud.google.com/architecture/landing-zones)): Adopción de despliegues base por fases, Shared VPC Hub-and-Spoke, Private Service Connect (PSC) y enrutamiento centralizado e inmutable de logs de auditoría.
- **Google Cloud Enterprise Foundations Blueprint** ([cloud.google.com/architecture/foundations](https://cloud.google.com/architecture/foundations)): Jerarquía por fases, guardrails mediante políticas organizacionales y CI/CD sin claves estáticas a través de Workload Identity Federation.

### 4.2 Decisiones Propias de Diseño e Innovaciones de Valor
1. **Gobernanza Nativa de Plataformas de IA y Agentes (`07-ai-governance`, `docs/ai-governance.md`):**
   - Extiende la cobertura del blueprint estándar con restricciones personalizadas CEL declarativas (`agent_platform_*`) que fuerzan CMEK y redes VPC privadas en Custom Training, Endpoints de Vertex AI y Vector Search.
   - Aplica políticas para Vertex AI Workbench (`ainotebooks.accessMode`, `ainotebooks.restrictPublicIp`).
2. **IAM Contextual con Common Expression Language (CEL) (`04-iam`):**
   - Aplica asignaciones de acceso condicional restringiendo las consultas de Legal/Auditoría y Ciencia de Datos a horarios laborales europeos (`08:00 - 18:00 UTC`).
   - Limita la suplantación de cuentas de servicio (impersonation) de despliegue de agentes estrictamente a identidades de cargas de trabajo dedicadas (`sa-agent-training`, `sa-agent-serving`, `sa-agent-vector-search`), previniendo la escalada de privilegios.
3. **Motor del Ciclo de Vida de VPC-SC Multi-Entorno (`modules/vpc-sc-perimeter`):**
   - Estandariza perímetros regulares y de puente entre entornos, operando `dev` en Dry-Run explícito (`use_explicit_dry_run_spec`) para telemetría sin frenar a los desarrolladores, `stg` para validación pre-productiva y `prod` en modo completamente Enforced.
4. **Operaciones de Seguridad Holísticas Multicapa:**
   - Security Command Center (SCC) transmitiendo notificaciones de hallazgos en tiempo real a Pub/Sub con configuraciones de mute en dev, Access Approval / Access Transparency para operaciones del personal de Google y retención inmutable de auditoría durante 7 años en BigQuery.
5. **Soberanía y Residencia Obligatoria de Datos en la UE:**
   - Restricción estricta `gcp.resourceLocations` que permite únicamente regiones europeas (`in:eu-locations`) para cumplimiento con el RGPD y el Reglamento de IA de la UE (EU AI Act).
