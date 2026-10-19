# Modelo IAM y Acceso Condicional (Mínimo Privilegio)

## 1. Arquitectura de Roles y Separación de Perfiles

Para garantizar una estricta separación de funciones y maximizar la seguridad operativa, los roles de IAM se asignan a Grupos de Google centralizados y a Cuentas de Servicio automatizadas, en lugar de a cuentas de usuario individuales.

```
+----------------------------------------------------------------------------------------------------+
|                                      Matriz Empresarial de IAM                                     |
+-------------------------------+-----------------------------------+--------------------------------+
| Perfil / Identidad            | Rol(es) Asignado(s)               | Condición CEL / Alcance        |
+-------------------------------+-----------------------------------+--------------------------------+
| Legal y Cumplimiento          | roles/bigquery.dataViewer         | Solo Horario Laboral           |
| (gcp-legal-compliance)        | roles/cloudsql.viewer             | (08:00 - 18:00 UTC)            |
+-------------------------------+-----------------------------------+--------------------------------+
| Operaciones de Seguridad (SOC)| roles/iam.securityReviewer        | Producción Completa            |
| (gcp-soc-secops)              | roles/logging.viewer              | Vista Incondicional            |
+-------------------------------+-----------------------------------+--------------------------------+
| Equipo de Plataforma Cloud    | roles/resourcemanager             | Folder Admin en                |
| (gcp-platform-devops)         | .folderViewer                     | No-Producción y Sandbox        |
+-------------------------------+-----------------------------------+--------------------------------+
| Acceso de Emergencia          | roles/resourcemanager             | Limitado en tiempo con         |
| (gcp-breakglass-admins)       | .folderAdmin                      | alerta de auditoría obligatoria|
+-------------------------------+-----------------------------------+--------------------------------+
| Científicos de Datos e IA     | roles/aiplatform.user             | Solo Horario Laboral           |
| (gcp-data-scientists)         | roles/bigquery.dataViewer         | (08:00 - 18:00 UTC)            |
|                               | roles/bigquery.jobUser            |                                |
|                               | roles/storage.objectViewer        |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Desplegadores de Agentes      | roles/aiplatform.admin            | Impersonación restringida solo |
| (gcp-agent-deployers)         | roles/storage.objectAdmin         | a Cuentas de Servicio dedicadas|
|                               | roles/iam.serviceAccountUser      | de Agentes (sa-agent-*)        |
+-------------------------------+-----------------------------------+--------------------------------+
| Auditores de IA y Compliance  | roles/aiplatform.viewer           | Solo Lectura en Producción     |
| (gcp-ai-auditors)             | roles/logging.viewer              | Auditoría de Modelos y Métricas|
|                               | roles/iam.securityReviewer        |                                |
|                               | roles/bigquery.dataViewer         |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Entrenamiento    | roles/aiplatform                  | Ejecución aislada por carga:   |
| (sa-agent-training)           | .customCodeServiceAgent           | Escritura GCS y Lectura BQ     |
|                               | roles/storage.objectAdmin         |                                |
|                               | roles/bigquery.dataViewer,jobUser |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Inferencia       | roles/aiplatform.serviceAgent     | Ejecución aislada por carga:   |
| (sa-agent-serving)            | roles/storage.objectViewer        | Carga de pesos y Logs          |
|                               | roles/logging.logWriter           |                                |
+-------------------------------+-----------------------------------+--------------------------------+
| Workload SA: Vector Search    | roles/aiplatform.user             | Ejecución aislada por carga:   |
| (sa-agent-vector-search)      | roles/storage.objectViewer        | Búsqueda y consulta en índices |
|                               | roles/logging.logWriter           |                                |
+-------------------------------+-----------------------------------+--------------------------------+
```

---

## 2. Especificaciones de Expresiones CEL (Common Expression Language)

### Restricción Horaria para Equipo Legal y Científicos de Datos
```cel
request.time.getHours('UTC') >= 8 && request.time.getHours('UTC') <= 18
```
- **Justificación:** Previene la extracción masiva de datos fuera de horario y mitiga el uso indebido de credenciales fuera de operaciones supervisadas. Aplica acceso acotado en el tiempo a datasets analíticos, recursos de Vertex AI y buckets de entrenamiento.

### Salvaguarda de Impersonación de Cuentas de Servicio para Desplegadores de Agentes
```cel
resource.name.extract('/serviceAccounts/{sa}').startsWith('sa-agent-')
```
- **Justificación:** Previene la escalada de privilegios garantizando que los equipos de MLOps y desplegadores de agentes solo puedan actuar en nombre de cuentas de servicio de IA dedicadas (`sa-agent-*`), bloqueando por completo la suplantación no autorizada de cuentas administrativas o de Terraform.

### Delimitación Temporal para Accesos de Emergencia (Break-Glass)
```cel
request.time < timestamp('2026-12-31T23:59:59Z')
```
- **Justificación:** Elimina privilegios elevados permanentes y garantiza una fecha límite de expiración.

---

## 3. Arquitectura de Cuentas de Servicio Dedicadas por Carga de Trabajo

Cada etapa de la plataforma de agentes y el ciclo de vida de IA se ejecuta bajo una Cuenta de Servicio independiente y dedicada, cumpliendo con el Principio de Mínimo Privilegio:

1. **`sa-agent-training`**: Dedicada a trabajos de entrenamiento personalizado (Custom Training Jobs), ajuste de hiperparámetros y pasos de entrenamiento en pipelines. Cuenta con `roles/aiplatform.customCodeServiceAgent`, `roles/storage.objectAdmin` en buckets de datos/salida de entrenamiento, y `roles/bigquery.dataViewer` + `roles/bigquery.jobUser`.
2. **`sa-agent-serving`**: Dedicada a endpoints de inferencia online e instancias de predicción en tiempo real. Cuenta con `roles/aiplatform.serviceAgent`, acceso de solo lectura a artefactos de modelos mediante `roles/storage.objectViewer`, y `roles/logging.logWriter` para trazabilidad de logs de inferencia.
3. **`sa-agent-vector-search`**: Dedicada a la indexación en Vector Search y recuperación de similitudes (RAG). Cuenta con `roles/aiplatform.user` y permisos de almacenamiento de solo lectura.
