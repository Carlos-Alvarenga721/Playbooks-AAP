# =============================================================================
# GUÍA DE CONFIGURACIÓN - AAP CONTROLLER
# =============================================================================
# CIS Compliance Workflow - Ansible Automation Platform
# =============================================================================

## 📋 RESUMEN DE CONFIGURACIÓN

Este documento describe cómo configurar el workflow de CIS Compliance 
en Ansible Automation Platform Controller para su uso con el Portal Self-Service.

---

## 1️⃣ CREAR PROYECTO

```yaml
Nombre: CIS-Compliance-Automation
Organización: Default
SCM Type: Git
URL del SCM: [URL de tu repositorio Git]
Branch: main
Opciones:
  ✅ Clean
  ✅ Update Revision on Launch
```

---

## 2️⃣ CREAR INVENTARIO

```yaml
Nombre: GCP-Servers-Inventory
Organización: Default
Variables:
  ---
  ansible_python_interpreter: /usr/bin/python3
```

### Grupos del Inventario:
| Grupo | Descripción |
|-------|-------------|
| `linux_servers` | Servidores Linux target (Web, App, DB) |
| `windows_servers` | Windows Domain Controller |
| `aap_infrastructure` | Controller y PostgreSQL |

### Hosts:
| Host | IP | Grupo |
|------|-----|-------|
| web-server | 10.128.0.6 | linux_servers |
| app-server | 10.128.0.7 | linux_servers |
| db-server | 10.128.0.8 | linux_servers |
| win-dc | 10.128.0.4 | windows_servers |

---

## 3️⃣ CREAR CREDENCIALES

### Credencial SSH (Linux):
```yaml
Nombre: GCP-Linux-SSH
Tipo: Machine
Username: ansible_admin
SSH Private Key: [Contenido de la llave privada]
Privilege Escalation: sudo
```

### Credencial SMTP (Email):
```yaml
Nombre: SMTP-Notifications
Tipo: Custom Credential
Variables:
  vault_smtp_user: "notificaciones@empresa.com"
  vault_smtp_password: "password_seguro"
```

---

## 4️⃣ CREAR PLANTILLAS DE TRABAJO (JOB TEMPLATES)

### 4.1 Template: CIS Audit Only
```yaml
Nombre: CIS-Audit-Scan
Tipo: Run
Inventario: GCP-Servers-Inventory
Proyecto: CIS-Compliance-Automation
Playbook: playbooks/01_cis_audit_scan.yml
Credencial: GCP-Linux-SSH
Opciones:
  ✅ Enable Privilege Escalation
```

### 4.2 Template: CIS Remediation
```yaml
Nombre: CIS-Remediation
Tipo: Run
Inventario: GCP-Servers-Inventory
Proyecto: CIS-Compliance-Automation
Playbook: playbooks/02_cis_remediation.yml
Credencial: GCP-Linux-SSH
Variables Extra:
  apply_remediation: true
Opciones:
  ✅ Enable Privilege Escalation
```

### 4.3 Template: CIS Full Workflow (Recomendado)
```yaml
Nombre: CIS-Compliance-Full-Workflow
Tipo: Run
Inventario: GCP-Servers-Inventory
Proyecto: CIS-Compliance-Automation
Playbook: playbooks/cis_compliance_workflow.yml
Credencial: GCP-Linux-SSH
Opciones:
  ✅ Enable Privilege Escalation
  ✅ Enable Survey
```

---

## 5️⃣ CONFIGURAR SURVEY (Formulario Self-Service)

### Survey para: CIS-Compliance-Full-Workflow

#### Pregunta 1: Servidores Target
```yaml
Prompt: ¿En qué servidores desea ejecutar la auditoría?
Variable: target_servers
Tipo: Multiple Choice (single select)
Opciones:
  - linux_servers (Todos los servidores Linux)
  - web-server (Solo servidor Web)
  - app-server (Solo servidor de Aplicaciones)
  - db-server (Solo servidor de Base de Datos)
Default: linux_servers
Requerido: Sí
```

#### Pregunta 2: Aplicar Remediación
```yaml
Prompt: ¿Desea aplicar remediación automática?
Variable: apply_remediation
Tipo: Multiple Choice (single select)
Opciones:
  - "false" → No, solo auditar
  - "true" → Sí, corregir problemas encontrados
Default: "false"
Requerido: Sí
```

#### Pregunta 3: Enviar Reporte por Email
```yaml
Prompt: ¿Enviar reporte por correo electrónico?
Variable: email_enabled
Tipo: Multiple Choice (single select)
Opciones:
  - "false" → No
  - "true" → Sí
Default: "false"
Requerido: Sí
```

#### Pregunta 4: Destinatarios (Condicional)
```yaml
Prompt: Correos electrónicos de destinatarios (separados por coma)
Variable: email_recipients
Tipo: Text
Default: seguridad@empresa.com
Requerido: No
```

---

## 6️⃣ CREAR WORKFLOW TEMPLATE (Opcional - Avanzado)

Para un workflow visual con aprobaciones:

```yaml
Nombre: CIS-Compliance-Workflow-Approval
Tipo: Workflow Template

Nodos:
  1. [INICIO] → CIS-Audit-Scan
       ↓
  2. [APROBACIÓN] → "¿Aprobar remediación?"
       ↓ (Si aprobado)
  3. CIS-Remediation
       ↓
  4. CIS-Audit-Scan (Re-auditoría)
       ↓
  5. [FIN] → Generate-Report
```

---

## 7️⃣ CONFIGURAR NOTIFICACIONES

### Notificación de Éxito:
```yaml
Nombre: CIS-Compliance-Success
Tipo: Email
Host: smtp.gmail.com
Puerto: 587
Destinatarios: it-ops@empresa.com, seguridad@empresa.com
```

### Notificación de Fallo:
```yaml
Nombre: CIS-Compliance-Failed
Tipo: Email
Host: smtp.gmail.com
Puerto: 587
Destinatarios: soc@empresa.com
```

---

## 8️⃣ PROGRAMAR EJECUCIONES (Schedules)

### Auditoría Diaria:
```yaml
Nombre: Daily-CIS-Audit
Template: CIS-Audit-Scan
Frecuencia: Diario
Hora: 02:00 AM
Zona Horaria: America/El_Salvador
Variables:
  target_servers: linux_servers
```

### Auditoría Semanal con Remediación:
```yaml
Nombre: Weekly-CIS-Remediation
Template: CIS-Compliance-Full-Workflow
Frecuencia: Semanal (Domingos)
Hora: 03:00 AM
Variables:
  target_servers: linux_servers
  apply_remediation: true
  email_enabled: true
```

---

## 📊 FLUJO DE EJECUCIÓN

```
┌─────────────────────────────────────────────────────────────────┐
│                    PORTAL SELF-SERVICE                          │
│  Usuario selecciona: Servidores, Remediación, Email            │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                 AAP CONTROLLER - API                            │
│  Recibe parámetros → Lanza Job Template                        │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               FASE 1: AUDITORÍA INICIAL                         │
│  Ejecuta: 01_cis_audit_scan.yml                                │
│  Resultado: Lista de controles PASS/FAIL                       │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               FASE 2: REMEDIACIÓN (Opcional)                    │
│  Ejecuta: 02_cis_remediation.yml                               │
│  Resultado: Correcciones aplicadas + Backups                   │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               FASE 3: RE-AUDITORÍA                              │
│  Verifica mejora post-remediación                              │
└─────────────────────┬───────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────────────┐
│               FASE 4: REPORTE + NOTIFICACIÓN                    │
│  Genera HTML → Envía Email → Guarda histórico                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔐 MEJORES PRÁCTICAS DE SEGURIDAD

1. **Usar Ansible Vault** para credenciales sensibles
2. **Limitar permisos** de Job Templates por equipo/rol
3. **Habilitar logging** completo en AAP Controller
4. **Revisar antes de remediar** - usar `apply_remediation=false` primero
5. **Backups automáticos** - el playbook crea backups antes de cambiar configs

---

## 📞 SOPORTE

Para dudas o problemas:
- Equipo de Seguridad: seguridad@empresa.com
- IT Operations: it-ops@empresa.com
