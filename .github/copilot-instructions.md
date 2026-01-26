Resumen del Proyecto - POC Ansible Automation Platform en GCP
Este proyecto consiste en implementar una Prueba de Concepto (POC) de Red Hat Ansible Automation Platform (AAP) completamente desplegada en Google Cloud Platform (GCP) para centralizar y automatizar operaciones de TI.

Objetivo Principal:
Transformar procesos manuales que toman 2-3 horas en tareas automatizadas de 3-5 minutos mediante un centro de automatización que gestiona servidores Windows y Linux en la nube.
Componentes Clave:

Infraestructura de Servidores en GCP
Total: 6 servidores

AAP Controller - RHEL 9 (4 vCPUs, 16GB RAM)
PostgreSQL Database - RHEL 9 (2 vCPUs, 8GB RAM)
Windows Domain Controller - Windows Server 2022 (4 vCPUs, 8GB RAM)
Linux Web Server - RHEL 9 (2 vCPUs, 4GB RAM)
Linux App Server - RHEL 9 (2 vCPUs, 4GB RAM)
Linux DB Server - RHEL 9 (2 vCPUs, 4GB RAM)

Motor central: Ansible Automation Platform desplegado en GCP (Controller + PostgreSQL)
Portal Self-Service: Interfaz web que consume la API de AAP para que usuarios ejecuten automatizaciones sin conocimiento técnico
Infraestructura objetivo: Servidores Windows (Active Directory) y Linux (Web, App, DB) en GCP

Casos de Uso Principales:

Gestión automatizada de empleados (altas/bajas en Windows y Linux)
Auditorías de seguridad y hardening según CIS Benchmark Level 1
Aprovisionamiento y destrucción automática de entornos temporales

Valor Agregado:

Sistema de notificaciones automáticas por email con reportes detallados (estado antes/después, actividades ejecutadas, resultados de auditorías)
Estandarización de seguridad en todos los servidores
Optimización de costos mediante gestión de recursos efímeros

El proyecto se ejecuta en 3 fases: diseño arquitectónico, despliegue de infraestructura, y desarrollo de workflows con validación piloto.

Todas las intrucciones que me des se centraran unicamente en la herramienta de Ansible Automation Platform, y los playbook creados en Ansible.




