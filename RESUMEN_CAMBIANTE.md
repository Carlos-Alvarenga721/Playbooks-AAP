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
- **Portal Self-Service** | Ubuntu 22.04 | `10.10.0.4` | ❌ No creado aún

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
- El Portal Self-Service consumirá la **API REST de AAP** → NO ejecuta Ansible directamente
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

## Repositorio GitHub actual
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

### Contenido de archivos clave

**`ansible.cfg`**
```ini
[defaults]
roles_path = roles
```

**`collections/requirements.yml`**
```yaml
---
collections:
  - name: community.general
    version: ">=7.0.0"
  - name: community.windows
    version: ">=1.11.0,<3.0.0"
```

**`inventories/hosts.yml`**
```yaml
all:
  children:
    linux_servers:
      hosts:
        web-server:
          ansible_host: 10.10.0.2
          ansible_user: ansible
          ansible_become: true
    windows_servers:
      hosts:
        windows-dc:
          ansible_host: 10.10.0.3
          ansible_connection: winrm
          ansible_winrm_transport: ntlm
          ansible_port: 5985
          ansible_winrm_scheme: http
```

**`roles/ad_users/defaults/main.yml`**
```yaml
---
ad_ou: "CN=Users,DC=datum,DC=local"
ad_domain: "datum.local"
employee_full_name: "Default User"
employee_password: ""
employee_role: "Domain Users"
employee_action: "alta"
```

**`roles/ad_users/tasks/main.yml`**
```yaml
---
- name: "AD | Crear usuario en Active Directory"
  community.windows.win_domain_user:
    name: "{{ employee_username }}"
    firstname: "{{ employee_full_name.split()[0] }}"
    surname: "{{ employee_full_name.split()[1] }}"
    password: "{{ employee_password }}"
    state: present
    enabled: true
    groups:
      - "Domain Users"
    update_password: on_create
  when: employee_action == "alta"

- name: "AD | Deshabilitar usuario en Active Directory"
  community.windows.win_domain_user:
    name: "{{ employee_username }}"
    state: present
    enabled: false
  when: employee_action == "baja"

- name: "AD | Reset de contraseña en Active Directory"
  community.windows.win_domain_user:
    name: "{{ employee_username }}"
    password: "{{ employee_password }}"
    state: present
    enabled: true
    password_expired: true
    update_password: always
  when: employee_action == "reset"
```

**`roles/oracle_users/defaults/main.yml`**
```yaml
---
oracle_home: "/opt/oracle/product/26ai/dbhomeFree"
oracle_pdb: "FREEPDB1"
oracle_host: "localhost"
oracle_port: "1521"
employee_action: "alta"
employee_role_anterior: ""
employee_oracle_username: ""
```

**`roles/oracle_users/tasks/main.yml`**
```yaml
---
- name: "Oracle | Crear usuario en FREEPDB1"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    CREATE USER {{ employee_oracle_username }} IDENTIFIED BY "{{ employee_password }}";
    GRANT CREATE SESSION TO {{ employee_oracle_username }};
    EXIT;
    EOF
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    ORACLE_SID: "FREE"
    PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  register: oracle_create_result
  changed_when: "'User created' in oracle_create_result.stdout"
  failed_when:
    - oracle_create_result.rc != 0
    - "'ORA-01920' not in oracle_create_result.stdout"
  when: employee_action == "alta"

- name: "Oracle | Asignar rol al usuario"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    GRANT {{ employee_role }} TO {{ employee_oracle_username }};
    EXIT;
    EOF
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    ORACLE_SID: "FREE"
    PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  register: oracle_grant_result
  changed_when: "'Grant succeeded' in oracle_grant_result.stdout"
  failed_when: oracle_grant_result.rc != 0
  when: employee_action == "alta"

- name: "Oracle | Bloquear usuario (baja)"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    ALTER USER {{ employee_oracle_username }} ACCOUNT LOCK;
    EXIT;
    EOF
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    ORACLE_SID: "FREE"
    PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  register: oracle_lock_result
  changed_when: "'User altered' in oracle_lock_result.stdout"
  failed_when: oracle_lock_result.rc != 0
  when: employee_action == "baja"

- name: "Oracle | Cambio de rol — revocar rol anterior"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    REVOKE {{ employee_role_anterior }} FROM {{ employee_oracle_username }};
    EXIT;
    EOF
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    ORACLE_SID: "FREE"
    PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  register: oracle_revoke_result
  changed_when: "'Revoke succeeded' in oracle_revoke_result.stdout"
  failed_when:
    - oracle_revoke_result.rc != 0
    - "'ORA-01951' not in oracle_revoke_result.stdout"
  when: employee_action == "cambio_rol"

- name: "Oracle | Cambio de rol — asignar rol nuevo"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    GRANT {{ employee_role }} TO {{ employee_oracle_username }};
    EXIT;
    EOF
  environment:
    ORACLE_HOME: "{{ oracle_home }}"
    ORACLE_SID: "FREE"
    PATH: "{{ oracle_home }}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
  register: oracle_newrole_result
  changed_when: "'Grant succeeded' in oracle_newrole_result.stdout"
  failed_when: oracle_newrole_result.rc != 0
  when: employee_action == "cambio_rol"
```

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
- `wf-cis-level1` ✅ funcional
  - `Start → jt-cis-level1 → jt-cis-remediation → jt-cis-report`
- `wf-emp-alta` ✅ funcional
  - `Start → jt-emp-ad-alta (Con éxito) → jt-emp-oracle-alta`
- `wf-emp-baja` ✅ funcional
  - `Start → jt-emp-ad-baja (Con éxito) → jt-emp-oracle-baja`

### Operaciones sin workflow (JT directo)
- Cambio de rol Oracle → lanzar `jt-emp-oracle-cambio-rol` directamente
- Reset contraseña AD → lanzar `jt-emp-ad-reset` directamente

### Variables por operación
```yaml
# Alta
employee_action: "alta"
employee_username: "carlos.alvarenga"
employee_full_name: "Carlos Alvarenga"
employee_password: "Datum2025!"
employee_role: "APP_READONLY"
employee_oracle_username: "CARLOS_ALVARENGA"

# Baja
employee_action: "baja"
employee_username: "carlos.alvarenga"
employee_oracle_username: "CARLOS_ALVARENGA"

# Cambio de rol Oracle
employee_action: "cambio_rol"
employee_oracle_username: "CARLOS_ALVARENGA"
employee_role_anterior: "APP_READONLY"
employee_role: "APP_OPERATOR"

# Reset contraseña AD
employee_action: "reset"
employee_username: "carlos.alvarenga"
employee_password: "NuevoPassword2025!"
```

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
## Estado: ❌ No iniciado

### Requisitos definidos
- VM Ubuntu 22.04 | `10.10.0.4` | e2-small → **no creada aún**
- Consume API REST de AAP — no ejecuta Ansible directamente
- Login con Google OAuth para capturar el correo del usuario
- Correo del usuario = destinatario dinámico del reporte CIS
- Formularios para disparar cada workflow/JT con sus variables correspondientes
- Al lanzar desde el portal, el username de AD va en minúsculas y el de Oracle en MAYÚSCULAS con guion bajo

### Flujo objetivo del portal
```
Usuario hace login con Google
→ Portal captura su correo
→ Usuario selecciona operación (CIS audit, Alta empleado, Baja, etc.)
→ Portal muestra formulario con campos necesarios
→ Portal transforma variables (ej: carlos.alvarenga → CARLOS_ALVARENGA)
→ Portal llama API REST de AAP con las variables
→ AAP ejecuta el workflow/JT correspondiente
→ Resultado visible en el portal
```

---

## Qué NO debe hacer la IA

### General
- Proponer inventario dinámico GCP
- Sugerir `subscription-manager register`
- Actualizar AAP a versión superior
- Proponer Oracle 19c o XE 21c
- Proponer mover Oracle a VM separada
- Sobrecomplicar el modelo Oracle

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

## 1. Portal Self-Service (siguiente paso)
- ❌ Crear VM Ubuntu 22.04 en GCP (`10.10.0.4`, e2-small)
- ❌ Definir stack tecnológico del portal (Node.js recomendado)
- ❌ Implementar login con Google OAuth
- ❌ Construir formularios por caso de uso (CIS, Alta, Baja, Cambio rol, Reset)
- ❌ Integrar con API REST de AAP
- ❌ Implementar transformación de variables (AD vs Oracle username)
- ❌ Lógica del break playbook disparado en background al hacer login

## 2. Automatización #3 — Entornos efímeros
- ❌ Diseño del flujo completo
- ❌ Playbooks de aprovisionamiento en GCE
- ❌ Playbooks de destrucción automática
- ❌ Integración con portal
