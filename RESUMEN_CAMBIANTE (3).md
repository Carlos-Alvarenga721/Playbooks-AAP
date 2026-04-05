# CONTEXTO ACTUALIZADO — POC AAP EN GCP

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
Cuando el tema sea extenso, avanzar por partes.

---

## Objetivo actual de la POC
Implementar un flujo de **Automatización como Servicio** con **Ansible Automation Platform en GCP**, donde un **Portal Self-Service** envíe formularios a la **API REST de AAP** para disparar automatizaciones reales sobre:
- Auditorías CIS Level 1
- Gestión de empleados (AD + Oracle)
- Aprovisionamiento de entornos efímeros

Flujo objetivo:
**Portal web → formulario → API REST de AAP → Job Template / Workflow → ejecución automática**

---

## Infraestructura actual

### VMs
- **aap-controller** | RHEL 9 | `10.10.0.10` | ✅ Listo
  - AAP 2.4 instalado con Ansible 2.15.13
  - PostgreSQL en el mismo host
  - pywinrm y requests-ntlm instalados manualmente en `/usr/lib/python3.11/site-packages/`
- **web-server** | RHEL 9 | `10.10.0.2` | ✅ Listo
  - Target CIS (auditoría y remediación completadas)
  - Oracle AI Database Free 26ai instalada y operativa
  - Hostname observado: `rhel-target` / `rhel-target.datum.sv`
- **Windows DC** | Windows Server 2022 | `10.10.0.3` | ✅ Listo
  - AD DS instalado y operativo
  - Dominio: `datum.local` | NetBIOS: `DATUM`
  - WinRM habilitado en HTTP/5985 con NTLM
  - Conectividad AAP → DC validada y funcional
- **Portal Self-Service** | Ubuntu 24.04 | `10.10.0.4` | ✅ Listo
  - IP pública estática: `34.60.3.144`
  - Dominio: `portal.datumselfservice.site`
  - HTTPS funcionando con Caddy v2.11.2
  - Backend Node.js + Express corriendo en puerto 3000
  - Frontend Angular compilado y servido por Express
  - pm2 configurado para persistencia del backend
  - Login con Google OAuth funcional
  - `.env` configurado con credenciales AAP y OAuth

### Red
- VPC: `vpc-aap-poc` ✅
- Subred: `10.10.0.0/24` ✅
- Firewall y conectividad base ✅
- WinRM cubierto por regla interna ✅

---

## Restricciones críticas — NUNCA IGNORAR

- RHEL 9 en GCP usa **RHUI** → NUNCA sugerir `subscription-manager register`
- PostgreSQL corre en el mismo host que AAP
- Inventario dinámico GCP descartado → se usa **inventario estático**
- El Portal Self-Service consume la **API REST de AAP** → NO ejecuta Ansible directamente
- El App Password de Gmail no debe ir en texto plano
- La credencial Vault de AAP guarda la **clave de desencriptación de Ansible Vault**
- `auditd` en RHEL 9 no acepta stop/start vía módulo service → usar `ansible.builtin.command`
- **NO usar Oracle 19c ni Oracle XE 21c** → la base es **Oracle AI Database Free 26ai**
- AAP versión **2.4** con Ansible **2.15.13**

---

## Restricciones de colecciones — CRÍTICO

- `microsoft.ad` **NO es compatible** con Ansible 2.15.13 (requiere 2.16+) → NO usar nunca
- `community.windows` versión 3.0.0 eliminó `win_domain_user` → fijar versión `<3.0.0`
- El módulo correcto para AD es `community.windows.win_domain_user` con versión `>=1.11.0,<3.0.0`
- NO actualizar AAP — rompe lo que ya funciona

---

## Restricciones de WinRM — CRÍTICO

- WinRM `basic` NO funciona en Domain Controllers
- WinRM `negotiate` NO funciona — el EE no tiene soporte
- WinRM `ntlm` SÍ funciona — es el transporte correcto para esta POC
- El usuario en `cred-winrm-dc` debe ser `Administrator` (sin prefijo de dominio)
- La contraseña NO debe estar en el inventario ni en variables de host — viene desde `cred-winrm-dc`
- NO agregar `ansible_password: "{{ ansible_password }}"` en ningún inventario — causa loop infinito
- pywinrm fue instalado manualmente en el AAP Controller porque el EE no lo incluía
- Los JTs de AD **nunca deben tener "Escalada de privilegios" activada** — Windows no es compatible con sudo

---

## Restricciones de Oracle — CRÍTICO

- Verificaciones manuales deben hacerse con `sqlplus / as sysdba` + `ALTER SESSION SET CONTAINER=FREEPDB1`
- `POC_AAP_ADMIN` NO tiene acceso a `DBA_USERS` directamente → usar sysdba para verificaciones manuales
- Los usuarios Oracle se crean en **MAYÚSCULAS** con guion bajo: `carlos.alvarenga` → `CARLOS_ALVARENGA`
- Variables de entorno requeridas en cada task Oracle: `ORACLE_HOME`, `ORACLE_SID`, `PATH`
- Usar `employee_oracle_username` para Oracle y `employee_username` para AD — son variables separadas

---

## Repositorio GitHub — Playbooks AAP
Repo: `https://github.com/Carlos-Alvarenga721/Playbooks-AAP`

### Estructura actual del repositorio
```text
ansible.cfg                          ✅ en raíz — roles_path = roles
collections/
  requirements.yml                   ✅ community.general + community.windows <3.0.0
inventories/
  gcp_compute.yml                    (descartado)
  hosts.yml                          ✅ actualizado con ntlm para windows-dc
playbooks/
  00_cis_break.yml                   ✅ funcional
  01_cis_audit.yml                   ✅ funcional
  02_cis_remediation.yml             ✅ funcional
  03_cis_report.yml                  ✅ funcional
  emp_ad_mgmt.yml                    ✅ funcional — llama al rol ad_users
  emp_oracle_mgmt.yml                ✅ funcional — llama al rol oracle_users
roles/
  cis_hardening/
    tasks/main.yml                   ✅ funcional
    templates/cis_report.html.j2     ✅ funcional
  ad_users/
    defaults/main.yml                ✅ actualizado
    tasks/main.yml                   ✅ maneja alta, baja, reset via employee_action
  oracle_users/
    defaults/main.yml                ✅ actualizado
    tasks/main.yml                   ✅ maneja alta, baja, cambio_rol via employee_action
vars/
  vault.yml                          ✅ cifrado con ansible-vault
```

---

## Repositorio GitHub — Portal Self-Service
Repo: monorepo Angular + Node.js/Express

### Estructura del portal
```text
backend/
  .env                               ✅ configurado en VM (NO en repo)
  src/
    aap.js                           ✅ launchWorkflow + launchJobTemplate + consulta de estado en AAP
    auth.js                          ✅ JWT middleware (signToken, verifyToken, authRequired)
    db.js                            ✅ SQLite con tabla users (email, role, active)
    index.js                         ✅ Express + passport.initialize()
    routes/
      auth.js                        ✅ Google OAuth (passport-google-oauth20) + /me
      jobs.js                        ✅ rutas: /cis, /employees/alta, /baja, /cambio-rol, /reset, /ephemeral/create, /ephemeral/delete, /status/:jobId
frontend/
  src/
    app/
      app.component.ts               ✅ captura token OAuth del callback en ngOnInit
      services/
        auth.service.ts              ✅ handleOAuthCallback + loginWithGoogle
        jobs.service.ts              ✅ payloads reales + consulta de estado de jobs
      pages/
        login/login.component.ts     ✅ botón "Continuar con Google"
        cis/cis.component.ts         ✅ lanza workflow CIS y muestra estado del job
        employees/employees.component.ts ✅ selector de operación + formularios por alta/baja/cambio/reset + estado del job
        ephemeral/ephemeral.component.ts ✅ formulario real para crear/eliminar VM + estado del job
```

### Estado actual del portal web
- Login con Google ✅
- Autorización local con SQLite ✅
- Gestión de empleados (alta, baja, cambio de rol, reset) desde el portal hacia AAP ✅
- Estandarización CIS desde el portal hacia workflow de AAP ✅
- Creación y eliminación de VM efímera desde el portal hacia Job Templates de AAP ✅
- Seguimiento de estado de jobs desde AAP (`pending`, `running`, `successful`, `failed`) ✅
- UI mejorada en módulos de empleados, CIS y entornos bajo demanda ✅

### Stack del portal
- **Frontend:** Angular (standalone components)
- **Backend:** Node.js + Express
- **Auth:** Google OAuth 2.0 + JWT
- **DB local:** SQLite (better-sqlite3) — usuarios autorizados
- **Proxy:** Caddy v2.11.2 (HTTPS automático)
- **Proceso:** pm2 (`portal-aap`)

### Variables de entorno del backend (`.env` en VM)
```env
GOOGLE_CLIENT_ID=...
GOOGLE_CLIENT_SECRET=...
GOOGLE_CALLBACK_URL=https://portal.datumselfservice.site/api/auth/google/callback
JWT_SECRET=datum-aap-poc-2025
AAP_URL=https://10.10.0.10
AAP_TOKEN=...
AAP_WF_CIS=14
AAP_WF_EMP_ALTA=22
AAP_WF_EMP_BAJA=23
AAP_WF_EMP_CAMBIO_ROL=24
AAP_JT_EMP_AD_RESET=21
AAP_JT_EPHEMERAL_VM_CREATE=...
AAP_JT_EPHEMERAL_VM_DELETE=...
PORT=3000
NODE_ENV=production
```

### Usuarios autorizados en SQLite
- Acceso controlado por BD local — Google solo verifica identidad
- Para agregar usuarios: `sqlite3 portal.db "INSERT OR REPLACE INTO users (email, role, active) VALUES ('correo@dominio.com', 'ops', 1);"`
- Roles: `ops` (técnico — acceso total) | `commercial` (no técnico — acceso limitado)

---

## IDs de Workflows y Job Templates en AAP

| Nombre | Tipo | ID |
|--------|------|----|
| `wf-cis-level1` | Workflow | 14 |
| `wf-emp-alta` | Workflow | 22 |
| `wf-emp-baja` | Workflow | 23 |
| `wf-emp-cambio-rol` | Workflow | 24 |
| `jt-cis-break` | Job Template | 15 |
| `jt-cis-level1` | Job Template | 11 |
| `jt-cis-remediation` | Job Template | 12 |
| `jt-cis-report` | Job Template | 13 |
| `jt-emp-ad-alta` | Job Template | 16 |
| `jt-emp-ad-baja` | Job Template | 18 |
| `jt-emp-ad-reset` | Job Template | 21 |
| `jt-emp-oracle-alta` | Job Template | 17 |
| `jt-emp-oracle-baja` | Job Template | 19 |
| `jt-emp-oracle-cambio-rol` | Job Template | 20 |
| `jt-ephemeral-vm-create` | Job Template | pendiente de documentar |
| `jt-ephemeral-vm-delete` | Job Template | pendiente de documentar |

---

## Estado actual en AAP

### Credenciales
- `cred-ssh-rhel-target` ✅
- `cred-vault-smtp` ✅ — clave de desencriptación Vault
- `cred-winrm-dc` ✅ — usuario: `Administrator`, transporte: ntlm
- `cred-oracle-admin` ✅ — tipo personalizado `Oracle DB Credential`
  - Inyecta `oracle_admin_user: POC_AAP_ADMIN` y `oracle_admin_password`

### Job Templates
- `jt-cis-break` ✅ funcional
- `jt-cis-level1` ✅ funcional
- `jt-cis-remediation` ✅ funcional
- `jt-cis-report` ✅ funcional
- `jt-emp-ad-alta` ✅ funcional — sin escalada de privilegios
- `jt-emp-ad-baja` ✅ funcional — sin escalada de privilegios
- `jt-emp-ad-reset` ✅ funcional — sin escalada de privilegios
- `jt-emp-oracle-alta` ✅ funcional — con escalada de privilegios
- `jt-emp-oracle-baja` ✅ funcional — con escalada de privilegios
- `jt-emp-oracle-cambio-rol` ✅ funcional — con escalada de privilegios

### Workflows
- `wf-cis-level1` ✅ funcional → `Start → jt-cis-level1 → jt-cis-remediation → jt-cis-report`
- `wf-emp-alta` ✅ funcional → `Start → jt-emp-ad-alta → jt-emp-oracle-alta`
- `wf-emp-baja` ✅ funcional → `Start → jt-emp-ad-baja → jt-emp-oracle-baja`
- `wf-emp-cambio-rol` ✅ funcional → lanza `jt-emp-oracle-cambio-rol`

### Operaciones sin workflow (JT directo)
- Reset contraseña AD → lanzar `jt-emp-ad-reset` (ID: 21) directamente
- VM efímera create → lanzar `jt-ephemeral-vm-create` directamente
- VM efímera delete → lanzar `jt-ephemeral-vm-delete` directamente

### Integración nueva validada en portal
- El portal ya envía formularios reales a AAP para empleados, CIS y VM efímera ✅
- El backend ya distingue Workflow Jobs (`/workflow_jobs/:id`) y Jobs normales (`/jobs/:id`) para leer estado ✅
- El frontend ya hace polling del estado del job y muestra avance visible al usuario ✅

---

# AUTOMATIZACIÓN #2 — CIS Level 1
## Estado: ✅ FUNCIONAL Y COMPLETA PARA DEMO

- Audit CIS con PASS/FAIL reales ✅
- Remediación automática ✅
- Reporte HTML generado y enviado por correo ✅
- Break playbook funcional ✅
- Transferencia de variables entre nodos con `set_stats` ✅

---

# AUTOMATIZACIÓN #1 — Gestión de Empleados (AD + Oracle)
## Estado: ✅ FUNCIONAL Y COMPLETA PARA DEMO

- Alta de empleado en AD + Oracle ✅
- Baja de empleado en AD + Oracle ✅
- Cambio de rol en Oracle ✅
- Reset de contraseña en AD ✅
- Probado end-to-end con usuario `roberto.carlos` / `ROBERTO_CARLOS` ✅

---

# AUTOMATIZACIÓN #3 — Entornos efímeros
## Estado: ❌ No iniciada

Pendiente de diseño e implementación.

---

# PORTAL SELF-SERVICE
## Estado: 🔄 En progreso

### Completado ✅
- VM Ubuntu 24.04 creada en GCP (`10.10.0.4`, e2-small)
- IP pública estática asignada (`34.60.3.144`)
- Dominio `datumselfservice.site` registrado en Hostinger
- DNS configurado: `portal.datumselfservice.site → 34.60.3.144`
- Caddy v2.11.2 instalado y configurado como reverse proxy con HTTPS automático
- Frontend Angular compilado y servido por Express en puerto 3000
- Backend Node.js funcional con rutas `/api/auth` y `/api/jobs`
- Google OAuth configurado en Google Cloud Console
- Login con Google funcional (`carlos.alvarenga@datumredsoft.com`)
- JWT generado correctamente al autenticar
- pm2 configurado con arranque automático (`pm2 startup` + `pm2 save`)
- `backend/src/aap.js` actualizado con `launchWorkflow` y `launchJobTemplate`
- `backend/src/routes/jobs.js` actualizado con todas las rutas de AAP
- IDs de workflows y JTs mapeados en `.env`

### Pendiente ❌
- Hacer `git pull` + rebuild en la VM con los últimos cambios de `aap.js` y `jobs.js`
- Construir formularios en el frontend Angular por caso de uso:
  - CIS Level 1 (botón simple → dispara `wf-cis-level1`)
  - Alta de empleado (formulario con campos → dispara `wf-emp-alta`)
  - Baja de empleado (formulario → dispara `wf-emp-baja`)
  - Cambio de rol (formulario → dispara `wf-emp-cambio-rol`)
  - Reset de contraseña AD (formulario → dispara `jt-emp-ad-reset`)
- Implementar transformación automática de username en el frontend:
  - `carlos.alvarenga` → `CARLOS_ALVARENGA` (para Oracle)
- Mostrar estado del job en el portal después de lanzarlo (job_id + estado)
- Lógica del break playbook disparado en background al hacer login (para demo CIS)
- Integrar correo del usuario logueado como destinatario dinámico del reporte CIS

---

## Qué NO debe hacer la IA

### General
- Proponer inventario dinámico GCP
- Sugerir `subscription-manager register`
- Actualizar AAP a versión superior
- Proponer Oracle 19c o XE 21c
- Proponer mover Oracle a VM separada
- Sobrecomplicar el modelo Oracle

### Portal
- NO modificar el `.env` directamente — está en la VM, no en el repo
- NO cambiar el puerto 3000 — Caddy apunta ahí
- NO tocar la configuración de Caddy — ya está funcional
- NO proponer autenticación distinta a Google OAuth — ya está implementada

### WinRM — NO volver a intentar
- NO usar `basic` como transporte WinRM en DC
- NO usar `negotiate` — el EE no lo soporta
- NO agregar `ansible_password: "{{ ansible_password }}"` en inventario
- NO usar `microsoft.ad` con Ansible 2.15
- NO usar `community.windows` versión 3.0.0+
- NO volver a instalar pywinrm — ya está instalado
- NO activar escalada de privilegios en JTs de AD

---

# ORACLE — NOTAS OPERATIVAS

## Variables de entorno requeridas en tasks Oracle
```yaml
environment:
  ORACLE_HOME: "{{ oracle_home }}"
  ORACLE_SID: "FREE"
  PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
```

## Verificación manual de usuarios Oracle
```bash
sudo su - oracle
sqlplus / as sysdba
```
```sql
ALTER SESSION SET CONTAINER=FREEPDB1;
SELECT username, account_status FROM dba_users WHERE username = 'NOMBRE_USUARIO';
SELECT grantee, granted_role FROM dba_role_privs WHERE grantee = 'NOMBRE_USUARIO';
```

## Estado validado
- Listener en puerto `1521` ✅
- `FREEPDB1` en `READ WRITE` ✅
- `POC_AAP_ADMIN` con privilegios CREATE/ALTER/DROP USER ✅
- Roles disponibles: `APP_READONLY`, `APP_OPERATOR`
- Usuarios demo: `EMP_DEMO_01`, `EMP_DEMO_02`

---

# PENDIENTES GLOBALES — EN ORDEN DE PRIORIDAD

## 1. Portal Self-Service — Formularios frontend (siguiente paso)
- ❌ `git pull` + rebuild frontend en la VM
- ❌ Formulario CIS Level 1 (componente `cis.component.ts`)
- ❌ Formulario Alta de empleado (componente `employees.component.ts`)
- ❌ Formulario Baja de empleado
- ❌ Formulario Cambio de rol
- ❌ Formulario Reset de contraseña AD
- ❌ Transformación automática AD username → Oracle username en frontend
- ❌ Visualización del job_id y estado tras lanzar desde el portal
- ❌ Break playbook en background al hacer login (para demo CIS)
- ❌ Correo del usuario logueado como destinatario dinámico del reporte CIS

## 2. Automatización #3 — Entornos efímeros
- ❌ Diseño del flujo completo
- ❌ Playbooks de aprovisionamiento en GCE
- ❌ Playbooks de destrucción automática
- ❌ Integración con portal


---

## Mejoras pendientes de UI
- Agregar historial visible de ejecuciones en dashboard
- Mostrar último `job_id`, estado final y hora de ejecución por módulo
- Traducir mejor mensajes de error técnicos de AAP/GCP a mensajes de negocio
- Mostrar enlace rápido al job en AAP cuando se lance una automatización
- Evaluar visibilidad condicional por rol (`ops` vs `commercial`)
- Unificar estilos visuales de tarjetas, botones y mensajes en todo el portal
