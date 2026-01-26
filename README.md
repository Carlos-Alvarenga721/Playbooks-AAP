# Prueba de Concepto: Ansible Automation Platform en Google Cloud Platform

## 📋 Descripción General

Este proyecto implementa una Prueba de Concepto (POC) de Red Hat Ansible Automation Platform (AAP) desplegada íntegramente sobre Google Cloud Platform (GCP). La solución actúa como un motor de orquestación centralizado para automatizar la gestión de infraestructura cloud, integrando un portal de autoservicio que consume las API de AAP para ejecutar flujos de trabajo complejos de manera simplificada.

## 🎯 Objetivo

Establecer un centro de automatización integral que centralice las operaciones de TI, reduciendo significativamente los tiempos de ejecución manual (de 2-3 horas a 3-5 minutos) mientras garantiza la estandarización y seguridad de la infraestructura mediante protocolos de hardening automatizados basados en CIS Benchmark Level 1.

---

## 🚀 Inicio Rápido

### Prerrequisitos
- Ansible 2.14+
- Python 3.9+
- Acceso SSH a servidores en GCP

### Comandos Básicos

```bash
# 1. Verificar conectividad
ansible-playbook playbooks/ping_test.yml -i inventories/gcp_hosts.yml

# 2. Ejecutar auditoría CIS (solo lectura)
ansible-playbook playbooks/01_cis_audit_scan.yml -i inventories/gcp_hosts.yml

# 3. Aplicar remediación
ansible-playbook playbooks/02_cis_remediation.yml -i inventories/gcp_hosts.yml -e "apply_remediation=true"

# 4. Generar reporte completo
ansible-playbook playbooks/03_generate_report.yml -i inventories/gcp_hosts.yml

# 5. Workflow completo (Auditoría + Remediación + Reporte)
ansible-playbook playbooks/cis_compliance_workflow.yml -i inventories/gcp_hosts.yml \
  -e "apply_remediation=true" -e "email_enabled=true"
```

---

## 📁 Estructura del Proyecto

```
AAP-PLAYBOOKS/
├── inventories/
│   └── gcp_hosts.yml          # Inventario de servidores GCP
├── group_vars/
│   └── all.yml                # Variables globales
├── playbooks/
│   ├── ping_test.yml          # Test de conectividad
│   ├── health_check.yml       # Verificación de salud
│   ├── 01_cis_audit_scan.yml  # Auditoría CIS Benchmark
│   ├── 02_cis_remediation.yml # Remediación automática
│   ├── 03_generate_report.yml # Generación de reportes
│   └── cis_compliance_workflow.yml  # Workflow completo
├── roles/
│   ├── cis_audit/             # Role de auditoría
│   ├── cis_remediation/       # Role de remediación
│   └── cis_reporting/         # Role de reportes
└── docs/
    └── AAP_CONTROLLER_SETUP.md # Guía de configuración AAP
```

---

## 🔒 Controles CIS Implementados

| Control | Descripción | Auditoría | Remediación |
|---------|-------------|:---------:|:-----------:|
| 1.1.1.1 | Módulo cramfs deshabilitado | ✅ | ✅ |
| 1.4.1 | Password en bootloader GRUB | ✅ | ⚠️ Manual |
| 1.5.1 | Permisos de /etc/motd | ✅ | ✅ |
| 3.4.1.1 | Firewalld instalado y activo | ✅ | ✅ |
| 4.2.1.1 | Rsyslog instalado y activo | ✅ | ✅ |
| 5.2.1 | Permisos de sshd_config | ✅ | ✅ |
| 5.2.4 | SSH root login deshabilitado | ✅ | ✅ |
| 5.2.11 | SSH MaxAuthTries ≤ 4 | ✅ | ✅ |
| 5.4.1.1 | Política expiración contraseñas | ✅ | ✅ |
| 6.1.1 | AIDE instalado | ✅ | ✅ |

---

## 🖥️ Infraestructura de Servidores

| Servidor | IP | Sistema | Rol |
|----------|-----|---------|-----|
| aap-controller | 10.128.0.2 | RHEL 9 | AAP Controller |
| postgresql | 10.128.0.5 | RHEL 9 | Base de datos AAP |
| win-dc | 10.128.0.4 | Windows 2022 | Domain Controller |
| web-server | 10.128.0.6 | RHEL 9 | Servidor Web |
| app-server | 10.128.0.7 | RHEL 9 | Servidor Aplicaciones |
| db-server | 10.128.0.8 | RHEL 9 | Servidor Base de Datos |

---

## 📊 Sistema de Reportes

El sistema genera reportes HTML profesionales con:
- 📈 Barra de progreso de cumplimiento
- 🎨 Código de colores (Verde >80%, Amarillo 50-80%, Rojo <50%)
- 📋 Detalle de cada control auditado
- 📧 Envío automático por email
- 🔄 Comparativa antes/después de remediación

---

## ⚙️ Configuración en AAP Controller

Ver documentación completa en: [docs/AAP_CONTROLLER_SETUP.md](docs/AAP_CONTROLLER_SETUP.md)

### Survey para Portal Self-Service:
- **target_servers**: Selección de servidores a auditar
- **apply_remediation**: Habilitar/deshabilitar correcciones
- **email_enabled**: Activar notificaciones por email

---

## Arquitectura de la Solución

### Componentes Principales

- **Ansible Automation Platform Controller**: Servidor central (RHEL 9) que aloja la interfaz web, motor de workflows y API REST
- **PostgreSQL**: Base de datos dedicada para almacenamiento de inventarios, credenciales e historial de ejecuciones
- **Portal Self-Service**: Interfaz web personalizada que consume la API de AAP para disparar automatizaciones
- **Infraestructura Target**: Servidores Windows (Active Directory) y Linux (Web, App, DB) gestionados por AAP

### Casos de Uso Implementados

1. **Gestión de Empleados**: Altas y bajas automatizadas en entornos Windows y Linux
2. **Auditoría de Seguridad**: Escaneos automáticos de cumplimiento CIS Benchmark Level 1
3. **Aprovisionamiento de Entornos**: Creación y destrucción automatizada de entornos temporales estandarizados

## Cronograma del Proyecto

### Fase 1: Planeación y Diseño (12-17 enero)
- Definición de requisitos y blueprint arquitectónico
- Diseño de VPC, subredes y reglas de firewall
- Planificación del portal y especificación de API

### Fase 2: Despliegue de Infraestructura (18-27 enero)
- Aprovisionamiento del ecosistema AAP en GCE
- Despliegue de servidores destino (Windows DC y servidores Linux)
- Configuración de credenciales, accesos e inventario dinámico

### Fase 3: Desarrollo y Validación (28 enero - 10 febrero)
- Desarrollo de playbooks y workflows
- Integración con portal self-service
- Ejecución piloto y hardening de seguridad

## Infraestructura GCP

La solución utiliza instancias de Google Compute Engine optimizadas para cada componente:

- **AAP Controller**: Instancia RHEL 9 con recursos para gestión de workflows
- **PostgreSQL**: Instancia dedicada para base de datos
- **Windows DC**: Active Directory para gestión centralizada
- **Servidores Linux**: Instancias Web, App y DB para casos de uso

**Seguridad**: Implementación de IAM, reglas de firewall, Ansible Vault para secretos y VPC segmentada.

## Elementos de Valor

- ⚡ **Reducción de Tiempos**: De 2-3 horas a 3-5 minutos por tarea
- 🔒 **Estandarización y Seguridad**: Cumplimiento nativo de políticas de hardening
- 💰 **Optimización de Costos**: Gestión eficiente de recursos efímeros con destrucción automática
- 📊 **Trazabilidad**: Historial completo de todas las ejecuciones y cambios

## Entregables

- Documento de diseño y planificación arquitectónica
- Infraestructura de automatización operativa en GCP
- Lógica de automatización (playbooks y workflows)
- Portal de autoservicio funcional
- Manuales de usuario y documentación técnica

## Requisitos Técnicos

- Cuenta activa de Google Cloud Platform
- Acceso a Red Hat Ansible Automation Platform
- Conocimientos en RHEL, Windows Server, y administración cloud
- Familiaridad con Infrastructure as Code (IaC) y YAML

## Tecnologías Utilizadas

- Red Hat Ansible Automation Platform
- Google Cloud Platform (Compute Engine, IAM, VPC)
- Red Hat Enterprise Linux 9
- PostgreSQL
- Windows Server / Active Directory
- CIS Benchmarks para hardening

## Contacto y Soporte

Para consultas sobre este proyecto, por favor contacte al equipo de DevOps o Infrastructure Automation.

---

**Fecha de Creación**: Enero 2026  
**Versión**: 1.0  
**Estado**: En Desarrollo