# CONTEXTO DE PROYECTO — POC AAP EN GCP

## Rol esperado de la IA
Actúa como un arquitecto senior experto en:
- Red Hat Ansible Automation Platform (AAP)
- Google Cloud Platform (GCP)
- Automatización empresarial
- Automatización como Servicio con AAP Controller

Debes responder con enfoque técnico, práctico y paso a paso.
No propongas rehacer cosas que ya fueron completadas.
No mezcles tareas futuras con el problema actual.
Prioriza el siguiente bloqueo técnico real.

---

## Objetivo actual de la POC
Implementar un flujo de **Automatización como Servicio** con **Ansible Automation Platform en GCP**, donde un **Portal Self-Service** dispare automatizaciones sobre casos de uso reales: auditorías CIS, gestión de empleados (AD + Oracle), y aprovisionamiento de entornos efímeros.

---

## Infraestructura actual

### VMs
- **aap-controller** | RHEL 9 | `10.10.0.10` | ✅ Listo
  - AAP instalado
  - PostgreSQL en el mismo host
- **web-server** | RHEL 9 | `10.10.0.2` | ✅ Listo
  - Target CIS (auditoría y remediación completadas)
  - Será también el servidor donde se instala Oracle 19c
- **Windows DC** | Windows 2022 | `10.10.0.30` | ⚠️ VM creada, sin AD instalado aún
- **Portal Self-Service** | Ubuntu 22.04 | `10.10.0.40` | ❌ No creado aún

### Red
- VPC: `vpc-aap-poc` ✅
- Subred: `10.10.0.0/24` ✅
- Firewall y conectividad base ✅

---

## Restricciones críticas
Estas restricciones son obligatorias. No las ignores ni sugieras lo contrario.

- RHEL 9 en GCP usa **RHUI**
- **NO usar** `subscription-manager register`
- PostgreSQL corre en el mismo host que AAP
- El inventario dinámico GCP fue intentado y descartado
- Se usa **inventario estático**
- El Portal Self-Service consumirá la **API REST de AAP**
- El portal **no ejecutará Ansible directamente**
- El App Password de Gmail **no debe ir en texto plano**
- La credencial tipo Vault de AAP **no guarda el App Password de Gmail**
- La credencial Vault de AAP debe guardar la **clave de desencriptación de Ansible Vault**
- El archivo `vars/vault.yml` existe y está cifrado con `ansible-vault`

---

## Repositorio GitHub actual
Repo:
`https://github.com/Carlos-Alvarenga721/Playbooks-AAP`

### Estructura actual
- `collections/requirements.yml`
- `inventories/hosts.yml`
- `playbooks/01_cis_audit.yml`
- `playbooks/02_cis_remediation.yml`
- `playbooks/03_cis_report.yml`
- `roles/cis_hardening/tasks/main.yml`
- `roles/cis_hardening/templates/cis_report.html.j2`
- `vars/vault.yml` ✅ agregado y cifrado con `ansible-vault`

---

## Estado actual en AAP

### Credenciales
- `cred-ssh-rhel-target` ✅
- `cred-vault-smtp` ✅
  - Contiene la clave de desencriptación del archivo Vault la cual es 123
  - No contiene el App Password de Gmail directamente

### Proyecto
- `proyecto-aap-poc` ✅
- sincronización Git funcionando ✅

### Inventario
- `inventario-aap-poc` ✅
- fuente estática funcionando ✅
- host `web-server` visible y usable ✅

### Job Templates
- `jt-cis-level1` ✅ funcional
- `jt-cis-remediation` ✅ funcional
- `jt-cis-report` ✅ funcional

### Workflow
- `wf-cis-level1` ✅ funcional

#### Flujo actual correcto
`Start → jt-cis-level1 → jt-cis-remediation → jt-cis-report`

#### Condiciones correctas
- `jt-cis-level1`: desde Start
- `jt-cis-remediation`: **Con éxito**
- `jt-cis-report`: **Siempre**

---

---

# AUTOMATIZACIÓN #2 — CIS Level 1 (RHEL 9)

## Estado: ✅ FUNCIONAL — Mejoras menores pendientes

### Lo que ya funciona al 100%
- AAP instalado y operativo en GCP ✅
- Conexión SSH desde AAP al `web-server` ✅
- Ejecución del audit CIS con resultados reales (PASS/FAIL) ✅
- Ejecución del playbook de remediación ✅
- Generación de reporte HTML ✅
- Envío del reporte por correo con Gmail SMTP ✅
- Transferencia de variables entre nodos con `ansible.builtin.set_stats` ✅
- Workflow completo funcionando con 3 nodos ✅
- Uso de Vault para proteger el secreto SMTP ✅

### Flujo funcional demostrado
1. AAP se conecta al `web-server`
2. Ejecuta auditoría CIS Level 1
3. Publica resultados reales (PASS/FAIL) vía `set_stats`
4. Ejecuta remediación si hay controles fallidos
5. Genera reporte HTML con conteos reales
6. Envía el reporte por correo al destinatario configurado

### Mejoras pendientes (no bloquean la demo)
- Mejorar la estructura visual del correo enviado
- Implementar login con Google en el Portal Self-Service para que el correo del usuario logueado se almacene como variable y sea el destinatario dinámico del reporte
- Break playbook para demo controlada (volver el servidor inseguro antes de demostrar)
- Agregar rama de error en el workflow (`jt-cis-report-failed`)

---

---

# AUTOMATIZACIÓN #1 — Gestión de Empleados (AD + Oracle 19c)

## Estado: 🔴 No iniciada

### Descripción
Automatizar la gestión del ciclo de vida de empleados sobre dos plataformas simultáneas: **Windows Active Directory** y **Oracle 19c en RHEL 9**.

### Los 4 procesos a automatizar

| # | Proceso | Targets |
|---|---------|---------|
| 1 | Alta de empleado | AD + Oracle |
| 2 | Cambio de rol / accesos | AD + Oracle |
| 3 | Baja de empleado | AD + Oracle |
| 4 | Reset / desbloqueo de cuenta | AD solamente |

### Infraestructura involucrada
- **Windows DC** (`10.10.0.30`) — Active Directory / Domain Controller
- **web-server** (`10.10.0.2`) — Oracle 19c se instalará aquí (mismo host que CIS target)

---

## Fases de implementación

### Fase 1 — Windows DC: instalación AD y conectividad AAP
**Estado: ⚠️ VM creada, AD no instalado**

Tareas pendientes:
- Instalar y promover el rol de Active Directory Domain Services (AD DS) en Windows Server 2022
- Configurar el dominio (definir nombre de dominio para el POC)
- Validar conectividad desde AAP Controller (`10.10.0.10`) hacia Windows DC (`10.10.0.30`)
  - Protocolo: WinRM o SSH (definir cuál usar con AAP)
- Crear credencial de tipo Windows en AAP (`cred-winrm-dc` o similar)
- Agregar el host `windows-dc` al inventario estático de AAP
- Validar que AAP puede ejecutar un módulo básico contra el DC (ping win, get facts)

### Fase 2 — Oracle 19c: instalación manual y definición de esquema
**Estado: ❌ No iniciada**

Tareas pendientes:
- Instalar Oracle 19c manualmente en el `web-server` (RHEL 9, `10.10.0.2`)
- Validar acceso local con `sqlplus`
- Validar acceso remoto desde AAP Controller
- Definir los roles/perfiles de usuario que se usarán en los casos de uso:
  - Alta: qué schema/role/tablespace se asigna por defecto
  - Cambio de rol: qué roles existen (ej. `ROL_OPERADOR`, `ROL_ADMIN`, etc.)
  - Baja: qué implica "dar de baja" en Oracle (lock account, revoke roles, etc.)
- Documentar el modelo de datos de usuario acordado antes de escribir playbooks

### Fase 3 — Automatización con AAP
**Estado: ❌ No iniciada**

Playbooks a crear:
- `playbooks/ad_oracle_alta.yml` — Crear usuario en AD + Oracle
- `playbooks/ad_oracle_cambio_rol.yml` — Modificar grupos AD + roles Oracle
- `playbooks/ad_oracle_baja.yml` — Deshabilitar en AD + lock en Oracle
- `playbooks/ad_reset_unlock.yml` — Reset/unlock en AD solamente

Roles a crear:
- `roles/ad_users/` — Gestión de usuarios en Active Directory
- `roles/oracle_users/` — Gestión de usuarios en Oracle 19c

Job Templates a crear en AAP:
- `jt-ad-oracle-alta`
- `jt-ad-oracle-cambio-rol`
- `jt-ad-oracle-baja`
- `jt-ad-reset-unlock`

Workflow a crear:
- `wf-gestion-empleados` — orquesta los 4 procesos según el tipo de operación seleccionada desde el portal

---

## Qué NO debe hacer otra IA (Automatización #1)
- Proponer inventario dinámico GCP
- Sugerir `subscription-manager register`
- Mezclar las tareas CIS con las tareas AD/Oracle
- Proponer instalar Oracle en una VM nueva (va en el `web-server` existente)
- Proponer arquitectura AD distinta a single DC (este es un POC)

---

---

# PENDIENTES GLOBALES DEL POC

## Portal Self-Service
- VM no creada aún ❌
- Pendiente para consumir API REST de AAP
- Debe implementar login con Google para capturar el correo del usuario como variable

## Break Playbook para demo CIS
- Crear playbook que revierta configuraciones de seguridad en el `web-server` para demostrar el flujo completo: FAIL → remediación → PASS

## Automatización #3 — Aprovisionamiento de entornos efímeros
- No iniciada
- Pendiente definir alcance

---

## Próximo paso recomendado
**Fase 1 de Automatización #1: instalar Active Directory en el Windows DC y validar conectividad desde AAP.**