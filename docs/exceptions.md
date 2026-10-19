# Gestión de Excepciones de Políticas y Gobernanza

## 1. Visión General del Proceso de Excepciones

Todas las políticas organizacionales, restricciones personalizadas y perímetros de VPC Service Controls se aplican por defecto (enforced). Cuando una aplicación requiere una excepción formal (por ejemplo, integración con un SaaS de terceros o un puente SFTP externo), el cambio debe seguir este ciclo de vida:

1. **Envío de Solicitud:** Justificación de negocio e impacto de amenazas presentado ante el Comité de Seguridad y Arquitectura Cloud (Cloud Architecture & Security Board).
2. **Revisión y Análisis:** Evaluación automatizada del riesgo frente a los requisitos de PCI-DSS y HIPAA.
3. **Aprobación:** Doble aprobación requerida por parte del CISO y el Responsable de Cumplimiento (Compliance Officer).
4. **Implementación:** Delimitación estricta a una carpeta o ID de proyecto específico mediante etiquetas/labels de Terraform y aprobaciones de ramas en Git.
5. **Revisión Periódica:** Revisión de expiración automatizada cada 90 días.

---

## 2. Esquema de Excepciones Registradas

Al declarar una excepción en Terraform, se definen los metadatos dentro de `exceptions.tf` o en las variables del proyecto:

```hcl
variable "approved_exception" {
  type = object({
    ticket_id       = string # ej. SEC-EXC-2026-089
    requester       = string # ej. payments-lead@bank.com
    reason          = string # Justificación
    expiry_date     = string # Marca de tiempo RFC3339
    target_resource = string # URI del recurso
  })
}
```
