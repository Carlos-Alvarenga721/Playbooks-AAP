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

- WinRM `basic` NO funciona en Domain Controllers (las cuentas de dominio no aceptan basic auth)
- WinRM `negotiate` NO funciona — el EE no tiene soporte
- WinRM `ntlm` SÍ funciona — es el transporte correcto para esta POC
- El usuario en `cred-winrm-dc` debe ser `Administrator` (sin prefijo de dominio)
- La contraseña NO debe estar en el inventario ni en variables de host — viene desde `cred-winrm-dc`
- NO agregar `ansible_password: "{{ ansible_password }}"` en ningún inventario — causa loop infinito
- pywinrm fue instalado manualmente en el AAP Controller porque el EE no lo incluía

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
  emp_oracle_mgmt.yml                ✅ creado — pendiente de prueba
roles/
  cis_hardening/
    tasks/main.yml                   ✅ funcional
    templates/cis_report.html.j2     ✅ funcional
  ad_users/
    defaults/main.yml                ✅ funcional
    tasks/main.yml                   ✅ funcional — usa community.windows.win_domain_user
  oracle_users/
    defaults/main.yml                ✅ creado
    tasks/main.yml                   ✅ creado — usa sqlplus vía ansible.builtin.shell
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
      - "{{ employee_role }}"
    update_password: on_create
```

**`roles/oracle_users/defaults/main.yml`**
```yaml
---
oracle_home: "/opt/oracle/product/26ai/dbhomeFree"
oracle_pdb: "FREEPDB1"
oracle_host: "localhost"
oracle_port: "1521"
```

**`roles/oracle_users/tasks/main.yml`**
```yaml
---
- name: "Oracle | Crear usuario en FREEPDB1"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    CREATE USER {{ employee_username }} IDENTIFIED BY "{{ employee_password }}";
    GRANT CREATE SESSION TO {{ employee_username }};
    EXIT;
    EOF
  register: oracle_create_result
  changed_when: "'User created' in oracle_create_result.stdout"
  failed_when:
    - oracle_create_result.rc != 0
    - "'ORA-01920' not in oracle_create_result.stdout"

- name: "Oracle | Asignar rol al usuario"
  ansible.builtin.shell: |
    {{ oracle_home }}/bin/sqlplus -S {{ oracle_admin_user }}/{{ oracle_admin_password }}@{{ oracle_host }}:{{ oracle_port }}/{{ oracle_pdb }} <<EOF
    GRANT {{ employee_role }} TO {{ employee_username }};
    EXIT;
    EOF
  register: oracle_grant_result
  changed_when: "'Grant succeeded' in oracle_grant_result.stdout"
  failed_when: oracle_grant_result.rc != 0
```

---

## Estado actual en AAP

### Credenciales
- `cred-ssh-rhel-target` ✅
- `cred-vault-smtp` ✅ — clave de desencriptación Vault
- `cred-winrm-dc` ✅
  - Tipo: Machine
  - Usuario: `Administrator` (sin prefijo de dominio)
  - Contraseña: `Datum2025!`
- `cred-oracle-admin` ✅ — tipo personalizado `Oracle DB Credential`
  - `oracle_admin_user`: `POC_AAP_ADMIN`
  - `oracle_admin_password`: contraseña real de POC_AAP_ADMIN

### Credential Type personalizado
- **Nombre:** `Oracle DB Credential`
- **Ruta:** Administración → Tipos de Credencial
- Inyecta `oracle_admin_user` y `oracle_admin_password` como extra_vars protegidas

### Variables del host `windows-dc` en UI de AAP
(Recursos → Inventarios → inventario-aap-poc → Hosts → windows-dc → Variables)
```json
{
  "ansible_host": "10.10.0.3",
  "ansible_connection": "winrm",
  "ansible_winrm_transport": "ntlm",
  "ansible_port": 5985,
  "ansible_winrm_scheme": "http"
}
```

### Job Templates
- `jt-cis-break` ✅ funcional
- `jt-cis-level1` ✅ funcional
- `jt-cis-remediation` ✅ funcional
- `jt-cis-report` ✅ funcional
- `jt-emp-ad-alta` ✅ FUNCIONAL — usuario creado en AD correctamente
  - Credencial: `cred-winrm-dc`
  - Variables extra con "Preguntar al ejecutar" activado
- `jt-emp-oracle-alta` ⚠️ creado — pendiente de prueba
  - Credenciales: `cred-ssh-rhel-target` + `cred-oracle-admin`
  - Elevación de privilegios: activada
  - Variables extra con "Preguntar al ejecutar" activado

### Workflows
- `wf-cis-level1` ✅ funcional
  - `Start → jt-cis-level1 → jt-cis-remediation → jt-cis-report`

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
## Estado: 🟡 AD funcional — Oracle pendiente de prueba

### Lo que ya funciona
- `jt-emp-ad-alta` ejecutado exitosamente ✅
- Usuario `prueba01` creado en `CN=Users,DC=datum,DC=local` ✅
- Verificado con `Get-ADUser -Identity "prueba01"` en el DC ✅

### Próximo paso inmediato
Probar `jt-emp-oracle-alta` con estas variables:
```yaml
employee_username: "prueba01"
employee_password: "Datum2025!"
employee_role: "APP_READONLY"
```

### Después de validar Oracle
1. Crear workflow `wf-gestion-empleados` que una AD + Oracle en secuencia
2. Crear playbooks/templates para baja y cambio de rol

---

## Modelo Oracle para gestión de empleados
- **Alta** = crear usuario + asignar rol Oracle
- **Cambio de rol** = revoke rol actual + grant rol nuevo
- **Baja** = lock del usuario Oracle
- **Reset** = solo AD

### Variables extra_vars para cada operación
```yaml
employee_username: "jlopez"
employee_full_name: "Juan Lopez"
employee_password: "Datum2025!"
employee_role: "APP_READONLY"   # o APP_OPERATOR / Domain Users
```

### Estructura Oracle ya creada en FREEPDB1
- Roles: `APP_READONLY`, `APP_OPERATOR`
- Usuario de automatización: `POC_AAP_ADMIN`
- Usuarios demo: `EMP_DEMO_01` (APP_READONLY), `EMP_DEMO_02` (APP_OPERATOR)

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

---

# ORACLE — NOTAS OPERATIVAS

## Variables de entorno del usuario `oracle` en web-server
```bash
export ORACLE_HOME=/opt/oracle/product/26ai/dbhomeFree
export ORACLE_SID=FREE
export PATH=$ORACLE_HOME/bin:$PATH
```

## Estado validado
- Listener en puerto `1521` ✅
- `FREEPDB1` en `READ WRITE` ✅
- `POC_AAP_ADMIN` con privilegios CREATE/ALTER/DROP USER ✅

---

# PENDIENTES GLOBALES

## Automatización #1 — Gestión de Empleados
- ✅ Alta en AD funcional
- ❌ Probar `jt-emp-oracle-alta`
- ❌ Crear workflow `wf-gestion-empleados` (AD + Oracle en secuencia)
- ❌ Baja de empleado (AD + Oracle)
- ❌ Cambio de rol (AD + Oracle)
- ❌ Reset/desbloqueo (solo AD)

## Portal Self-Service
- ❌ VM Ubuntu 22.04 no creada
- Debe consumir API REST de AAP
- Login con Google (OAuth) para capturar correo del usuario
- Correo del usuario = destinatario dinámico del reporte CIS

## Automatización #3 — Entornos efímeros
- ❌ No iniciada
