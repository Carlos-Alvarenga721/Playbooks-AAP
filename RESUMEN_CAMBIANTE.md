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
  - AAP instalado
  - PostgreSQL en el mismo host
- **web-server** | RHEL 9 | `10.10.0.2` | ✅ Listo
  - Target CIS (auditoría y remediación completadas)
  - En este mismo host quedó instalada y operativa **Oracle AI Database Free 26ai**
  - Hostname observado durante la configuración: `rhel-target` / `rhel-target.datum.sv`
- **Windows DC** | Windows Server 2022 | `10.10.0.3` | ✅ Listo
  - AD DS instalado y operativo
  - Dominio: `datum.local`
  - NetBIOS: `DATUM`
  - WinRM habilitado en HTTP/5985
  - Conectividad AAP → DC validada con `win_ping`
- **Portal Self-Service** | Ubuntu 22.04 | `10.10.0.4` | ❌ No creado aún

### Red
- VPC: `vpc-aap-poc` ✅
- Subred: `10.10.0.0/24` ✅
- Firewall y conectividad base ✅
- WinRM cubierto por regla interna ✅

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
- `auditd` en RHEL 9 **no acepta stop/start vía módulo service**
  - usar `service auditd stop` vía `ansible.builtin.command`
- Windows DC usa autenticación básica WinRM sobre HTTP/5985 para la POC
- **NO usar Oracle 19c en esta POC**
- **NO usar Oracle XE 21c** como ruta principal para RHEL 9
- La base Oracle elegida para la POC es **Oracle AI Database Free 26ai**
- El nombre “AI” es solo branding; no se usarán funciones de IA en la POC
- La prioridad es demostrar automatización funcional desde AAP, no hardening avanzado de Oracle

---

## Repositorio GitHub actual
Repo: `https://github.com/Carlos-Alvarenga721/Playbooks-AAP`

### Estructura actual conocida
```text
collections/requirements.yml
inventories/hosts.yml
playbooks/
  00_cis_break.yml          ✅ funcional
  01_cis_audit.yml          ✅ funcional
  02_cis_remediation.yml    ✅ funcional
  03_cis_report.yml         ✅ funcional
roles/
  cis_hardening/
    tasks/main.yml
    templates/cis_report.html.j2
vars/
  vault.yml                 ✅ cifrado con ansible-vault
```

---

## Estado actual en AAP

### Credenciales
- `cred-ssh-rhel-target` ✅
- `cred-vault-smtp` ✅
  - Contiene la clave de desencriptación del archivo Vault
  - No contiene el App Password de Gmail directamente
- `cred-winrm-dc` ✅
  - Tipo: Machine
  - Usuario: `Administrator`
  - Contraseña: `Datum2025!`

### Proyecto
- `proyecto-aap-poc` ✅
- Sincronización Git funcionando ✅

### Inventario
- `inventario-aap-poc` ✅
- Fuente estática funcionando ✅
- Host `web-server` ✅
- Host `windows-dc` ✅
- El host `web-server` también será el target para la automatización Oracle, porque Oracle quedó instalada en ese mismo servidor

### Job Templates
- `jt-cis-break` ✅ funcional
- `jt-cis-level1` ✅ funcional
- `jt-cis-remediation` ✅ funcional
- `jt-cis-report` ✅ funcional

### Workflow
- `wf-cis-level1` ✅ funcional

#### Flujo actual correcto
`Start → jt-cis-level1 → jt-cis-remediation → jt-cis-report`

#### Condiciones correctas
- `jt-cis-level1`: desde Start
- `jt-cis-remediation`: Con éxito
- `jt-cis-report`: Siempre

---

# AUTOMATIZACIÓN #2 — CIS Level 1 (RHEL 9)

## Estado: ✅ FUNCIONAL Y COMPLETA PARA DEMO

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
- Break playbook funcional para demo controlada ✅

### Flujo de demo funcional
1. Se ejecuta `jt-cis-break` manualmente → deja el servidor con 4 controles inseguros
2. Se ejecuta `wf-cis-level1` desde AAP (o futuro portal):
   - Auditoría detecta los FAILs reales
   - Remediación corrige cada control fallido
   - Reporte HTML se genera con conteos reales (PASS/FAIL)
   - Correo se envía al destinatario configurado

### Detalles del Break Playbook (`00_cis_break.yml`)
Controles que deja en estado inseguro (4 FAILs):
- `PermitRootLogin yes`
- `PasswordAuthentication yes`
- `firewalld` detenido y deshabilitado
- `auditd` detenido y deshabilitado

### Mejoras pendientes (no bloquean la demo)
- Implementar login con Google en el Portal Self-Service para que el correo del usuario logueado sea el destinatario dinámico del reporte
- Agregar rama de error en el workflow (`jt-cis-report-failed`)
- Disparar el break playbook automáticamente desde el portal al hacer login o desde una acción de prueba controlada

---

# AUTOMATIZACIÓN #1 — Gestión de Empleados (AD + Oracle Free 26ai)

## Estado: 🟡 En progreso real

### Descripción
Automatizar la gestión del ciclo de vida de empleados sobre dos plataformas simultáneas:
- **Windows Active Directory**
- **Oracle AI Database Free 26ai en RHEL 9**

### Los 4 procesos definidos para el portal
| # | Proceso | Targets |
|---|---------|---------|
| 1 | Alta de empleado | AD + Oracle |
| 2 | Cambio de rol / accesos | AD + Oracle |
| 3 | Baja de empleado | AD + Oracle |
| 4 | Reset / desbloqueo | AD solamente |

### Decisiones funcionales ya tomadas
- La gestión de usuarios será uno de los casos de uso principales del portal ✅
- El portal tendrá 4 opciones hijas dentro de “Gestión de usuarios” ✅
- Cada opción tendrá su propio formulario ✅
- El formulario enviará datos a AAP para disparar el playbook o workflow correspondiente ✅

### Infraestructura involucrada
- **Windows DC** (`10.10.0.3`) — Active Directory / Domain Controller ✅
- **web-server** (`10.10.0.2` / hostname observado `rhel-target`) — RHEL 9 con Oracle Free 26ai instalada en el mismo host ✅
- **AAP Controller** — orquestación y exposición vía API ✅

---

## Fases de implementación

### Fase 1 — Windows DC: instalación AD y conectividad AAP
**Estado: ✅ COMPLETADA**

Lo que se hizo:
- AD DS instalado y promovido en Windows Server 2022 ✅
- Dominio creado: `datum.local` | NetBIOS: `DATUM` ✅
- WinRM habilitado con autenticación básica sobre HTTP (puerto 5985) ✅
- Host `windows-dc` agregado al inventario estático de AAP ✅
- Credencial `cred-winrm-dc` creada en AAP ✅
- Test `win_ping` desde AAP exitoso ✅

### Fase 2 — Oracle Free 26ai: instalación y estructura mínima del MVP
**Estado: ✅ COMPLETADA A NIVEL BASE**

Lo que se hizo:
- Se descartó Oracle 19c para esta POC por incompatibilidad práctica con RHEL 9 sin acceso a parches/RU de MOS ✅
- Se descartó Oracle XE 21c como ruta principal ✅
- Se instaló **Oracle AI Database Free 26ai** en el mismo `web-server` RHEL 9 donde se ejecuta la automatización CIS ✅
- La base quedó configurada y operativa ✅
- Listener validado en puerto `1521` ✅
- Conexión local con `sqlplus / as sysdba` validada ✅
- PDB `FREEPDB1` validada en estado `READ WRITE` ✅

### Estructura mínima Oracle ya creada para la POC
#### Roles locales en `FREEPDB1`
- `APP_READONLY` ✅
- `APP_OPERATOR` ✅

#### Usuarios creados
- `POC_AAP_ADMIN` ✅
- `EMP_DEMO_01` ✅
- `EMP_DEMO_02` ✅

#### Asignaciones actuales
- `EMP_DEMO_01` → `APP_READONLY` ✅
- `EMP_DEMO_02` → `APP_OPERATOR` ✅
- `POC_AAP_ADMIN` → `APP_READONLY` con `ADMIN OPTION` ✅
- `POC_AAP_ADMIN` → `APP_OPERATOR` con `ADMIN OPTION` ✅

#### Privilegios confirmados para `POC_AAP_ADMIN`
- `CREATE SESSION` ✅
- `CREATE USER` ✅
- `ALTER USER` ✅
- `DROP USER` ✅
- `CREATE ROLE` ✅

### Modelo Oracle mínimo acordado para la POC
- **Alta** = crear usuario + asignar rol Oracle
- **Cambio de rol** = revoke rol actual + grant rol nuevo
- **Baja** = lock del usuario Oracle
- **Reset / desbloqueo** = solo AD por ahora

### Fase 3 — Automatización con AAP
**Estado: ❌ No iniciada todavía**

### Decisión de diseño para acelerar el MVP
En lugar de crear desde el inicio 4 automatizaciones Oracle separadas, se recomienda arrancar con:
- **1 template o workflow principal** para Oracle/gestión de usuarios
- Una variable `action` para decidir la operación:
  - `alta`
  - `cambio_rol`
  - `baja`

### Contrato mínimo esperado Portal → AAP
Ejemplo conceptual vía `extra_vars`:

```json
{
  "action": "alta",
  "oracle_username": "jlopez",
  "oracle_role": "APP_READONLY",
  "temporary_password": "Datum2025",
  "requested_by": "portal"
}
```

Para `cambio_rol`:
```json
{
  "action": "cambio_rol",
  "oracle_username": "jlopez",
  "oracle_role": "APP_OPERATOR",
  "requested_by": "portal"
}
```

Para `baja`:
```json
{
  "action": "baja",
  "oracle_username": "jlopez",
  "requested_by": "portal"
}
```

### Lo siguiente pendiente en esta automatización
1. Definir la cuenta/credencial con la que AAP se conectará a Oracle
2. Crear el playbook base para Oracle usando `POC_AAP_ADMIN`
3. Crear el playbook o role para AD
4. Integrar ambos en flujo de alta, cambio de rol y baja
5. Crear Job Templates en AAP
6. Exponerlos al portal vía API REST

### Playbooks/roles esperados a crear
- `playbooks/ad_oracle_alta.yml`
- `playbooks/ad_oracle_cambio_rol.yml`
- `playbooks/ad_oracle_baja.yml`
- `playbooks/ad_reset_unlock.yml`
- `roles/ad_users/`
- `roles/oracle_users/`

### Templates / workflows esperados en AAP
Opción mínima viable:
- `jt-oracle-user-mgmt`
- `jt-ad-reset-unlock`
- luego separar templates si hace falta

Opción más estructurada más adelante:
- `jt-ad-oracle-alta`
- `jt-ad-oracle-cambio-rol`
- `jt-ad-oracle-baja`
- `jt-ad-reset-unlock`
- `wf-gestion-empleados`

---

## Qué NO debe hacer otra IA (Automatización #1)
- Proponer inventario dinámico GCP
- Sugerir `subscription-manager register`
- Mezclar las tareas CIS con las tareas AD/Oracle
- Proponer Oracle 19c para esta POC
- Proponer mover Oracle a una VM separada sin necesidad
- Proponer Oracle XE 21c como solución principal
- Proponer arquitectura AD distinta a single DC
- Volver a configurar WinRM o recrear credenciales de Windows si no hay fallo real
- Sobrecomplicar el modelo Oracle con esquemas/tablaspaces/perfiles innecesarios para el MVP

---

# ESTADO DE ORACLE — NOTAS OPERATIVAS ÚTILES

## Estado validado
- Listener responde correctamente ✅
- Servicio `FREE` listo ✅
- Servicio `FREEPDB1` listo ✅
- `FREEPDB1` en `READ WRITE` ✅

## Ajustes operativos recomendados
- Habilitar el servicio `oracle-free-26ai` al arranque del sistema
- Guardar el estado de `FREEPDB1` si aún no se hizo (`SAVE STATE`)
- Dejar variables Oracle en `~/.bash_profile` del usuario `oracle`

## Variables de entorno útiles para el usuario `oracle`
```bash
export ORACLE_HOME=/opt/oracle/product/26ai/dbhomeFree
export ORACLE_SID=FREE
export PATH=$ORACLE_HOME/bin:$PATH
```

---

# PENDIENTES GLOBALES DEL POC

## Portal Self-Service
- VM no creada aún ❌
- Debe consumir la API REST de AAP
- Debe tener formularios por cada operación de gestión de usuarios
- Debe implementar login con Google (OAuth) para capturar el correo del usuario
- El correo del usuario logueado debe usarse como destinatario dinámico del reporte CIS
- Más adelante puede disparar `jt-cis-break` como acción controlada de demo

## Automatización #3 — Aprovisionamiento de entornos efímeros
- No iniciada ❌
- Pendiente definir alcance mínimo viable

---

## Próximo paso recomendado
**Construir la automatización mínima viable de Gestión de Empleados en AAP**, empezando por Oracle:
1. Crear el playbook base que reciba `action`, `oracle_username` y `oracle_role`
2. Ejecutar operaciones Oracle contra `FREEPDB1` usando `POC_AAP_ADMIN`
3. Probar primero `alta`, luego `cambio_rol`, luego `baja`
4. Después integrar la parte AD
5. Finalmente conectar el portal a la API REST de AAP
