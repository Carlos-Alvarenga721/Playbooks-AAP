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
Implementar un flujo de **Automatización como Servicio** con **Ansible Automation Platform en GCP**, donde un **Portal Self-Service** dispare auditorías **CIS Level 1** sobre un servidor **RHEL 9**, ejecute remediación y genere un **reporte HTML enviado por correo**.

---

## Infraestructura actual

### VMs
- **aap-controller** | RHEL 9 | `10.10.0.10` | ✅ Listo
  - AAP instalado
  - PostgreSQL en el mismo host
- **web-server** | RHEL 9 | `10.10.0.2` | ✅ Listo
  - Único target Linux para CIS
- **Windows DC** | Windows 2022 | `10.10.0.3` | ❌ No creado aún
- **Portal Self-Service** | Ubuntu 22.04 | `10.10.0.4` | ❌ No creado aún

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
- `cred-vault-smtp` ✅ corregida conceptualmente
  - **Debe contener** la clave de desencriptación del archivo Vault
  - **No debe contener** el App Password de Gmail

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

**No sugerir cambiar este workflow por ahora**, salvo que el cambio esté directamente relacionado con el siguiente problema técnico real.

---

## Lo que ya fue logrado
Estas cosas ya funcionan. No proponerlas como pendientes.

### Técnico
- AAP instalado y operativo en GCP ✅
- conexión SSH desde AAP al target Linux ✅
- ejecución del audit CIS ✅
- ejecución del playbook de remediación ✅
- generación de reporte HTML ✅
- envío del reporte por correo con Gmail SMTP ✅
- workflow completo funcionando con 3 nodos ✅
- uso de Vault para proteger el secreto SMTP ✅

### Flujo funcional demostrado
La demo actual ya prueba:
1. AAP se conecta al `web-server`
2. ejecuta auditoría CIS
3. intenta remediar si hay algo que corregir
4. si no hay nada que remediar, no hace cambios
5. genera un reporte
6. envía el reporte por correo

---

## Estado por nodo

### Nodo 1 — `jt-cis-level1`
- conecta al target ✅
- verifica controles CIS ✅
- termina exitosamente ✅

### Nodo 2 — `jt-cis-remediation`
- ejecuta sin errores ✅
- si no hay nada que corregir, no hace cambios ✅
- ese comportamiento es correcto ✅

### Nodo 3 — `jt-cis-report`
- genera HTML ✅
- lee el reporte ✅
- envía por correo ✅

---

## Problema actual principal
El correo llega correctamente, pero el reporte muestra:

- `PASS = 0`
- `FAIL = 0`

Eso **no está bien** para este caso.

### Qué significa
- el reporte sí se genera
- el SMTP sí funciona
- el workflow sí funciona
- pero el reporte **no está recibiendo los resultados reales del audit**

### Causa más probable
Cada Job Template del workflow corre como un job separado.
Las variables generadas en `jt-cis-level1` **no viajan automáticamente** a `jt-cis-report`.

---

## Siguiente trabajo técnico real
Hay que ajustar los playbooks para pasar resultados entre nodos usando artifacts del workflow, normalmente con:

- `ansible.builtin.set_stats`

---

## Lo que falta hacer en playbooks

### En `01_cis_audit.yml`
Hace falta:
- consolidar los resultados de cada control en una estructura como `cis_results`
- publicar los resultados con `ansible.builtin.set_stats`

La estructura conceptual esperada es algo como:
- `control`
- `estado`
- `detalle`

También debe publicar:
- `cis_total_controls`
- `cis_pass_count`
- `cis_fail_count`

### En `03_cis_report.yml`
Hace falta:
- asegurarse de consumir las variables publicadas por el audit
- usar esas variables para construir el resumen del correo

### En `roles/cis_hardening/templates/cis_report.html.j2`
Hace falta:
- iterar sobre la lista real de resultados
- mostrar el total real de controles
- mostrar PASS y FAIL reales

---

## Qué NO debe hacer otra IA
No sugerir ni rehacer estas cosas, porque ya fueron resueltas:

- reinstalar AAP
- volver a configurar SSH al target
- volver a crear el inventario estático
- volver a crear el proyecto Git
- volver a crear credenciales base
- volver a arreglar la ruta del template HTML
- volver a arreglar el envío SMTP
- volver a explicar la diferencia entre App Password y Vault Password
- volver a rediseñar el workflow base
- volver a proponer inventario dinámico GCP
- sugerir `subscription-manager register`

---

## Qué sí puede sugerir más adelante, pero no es prioridad ahora
Estas cosas son válidas, pero no son el siguiente paso inmediato:

- agregar rama de error en el workflow
- crear un `jt-cis-report-failed`
- crear Windows DC
- crear Portal Self-Service
- integrar el portal con API REST de AAP
- crear un break playbook para demo
- robustecer manejo de errores y notificaciones

---

## Pendientes identificados fuera del alcance inmediato

### Windows DC
- no creado aún ❌
- pendiente para casos de uso AD / empleados

### Portal Self-Service
- no creado aún ❌
- pendiente para consumir API REST de AAP

### Break playbook para demo
Pendiente:
- crear un playbook que vuelva inseguro el servidor antes de la demo
- permitir mostrar:
  - FAIL inicial
  - remediación
  - reporte final

---

## Estado real del POC hoy

### Ya probado con éxito
- infraestructura base en GCP
- AAP operativo
- repositorio conectado
- inventario estático
- credenciales
- workflow
- auditoría
- remediación
- reporte por correo

### Aún no cerrado al 100%
- persistencia / transferencia de resultados entre jobs
- conteo real PASS/FAIL en el reporte
- Portal Self-Service
- Windows DC
- rama de errores más robusta
- break playbook para demo controlada

---

## Próximo paso recomendado
El siguiente paso correcto es:

**Revisar y ajustar `01_cis_audit.yml` para publicar resultados con `ansible.builtin.set_stats`.**

Después de eso:
1. ajustar el template HTML
2. volver a correr el workflow
3. validar que el reporte ya muestre PASS y FAIL reales

---

## Instrucción operativa para la siguiente IA
Tu tarea actual NO es rehacer la arquitectura.
Tu tarea actual es resolver el problema de transferencia de resultados del audit hacia el reporte.

Empieza revisando:
- `playbooks/01_cis_audit.yml`
- `playbooks/03_cis_report.yml`
- `roles/cis_hardening/templates/cis_report.html.j2`

Objetivo inmediato:
- hacer que el reporte muestre resultados reales de cumplimiento CIS en lugar de `0/0`.

