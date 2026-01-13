# Prueba de Concepto: Ansible Automation Platform en Google Cloud Platform

## Descripción General

Este proyecto implementa una Prueba de Concepto (POC) de Red Hat Ansible Automation Platform (AAP) desplegada íntegramente sobre Google Cloud Platform (GCP). La solución actúa como un motor de orquestación centralizado para automatizar la gestión de infraestructura cloud, integrando un portal de autoservicio que consume las API de AAP para ejecutar flujos de trabajo complejos de manera simplificada.

## Objetivo

Establecer un centro de automatización integral que centralice las operaciones de TI, reduciendo significativamente los tiempos de ejecución manual (de 2-3 horas a 3-5 minutos) mientras garantiza la estandarización y seguridad de la infraestructura mediante protocolos de hardening automatizados basados en CIS Benchmark Level 1.

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