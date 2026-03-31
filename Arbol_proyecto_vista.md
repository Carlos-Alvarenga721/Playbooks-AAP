AAP PLAYBOOKS/
│
├── .github/
├── .vscode/
├── collections/
│
├── inventories/
│   ├── gcp_compute.yml
│   └── hosts.yml
│
├── playbooks/
│   ├── 00_cis_break.yml
│   ├── 01_cis_audit.yml
│   ├── 02_cis_remediation.yml
│   ├── 03_cis_report.yml
│   ├── emp_ad_mgmt.yml
│   └── emp_oracle_mgmt.yml
│
├── roles/
│   ├── ad_users/
│   │   ├── defaults/
│   │   │   └── main.yml
│   │   └── tasks/
│   │       └── main.yml
│   │
│   ├── cis_hardening/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   └── templates/
│   │       └── cis_report.html.j2
│   │
│   └── oracle_users/
│       ├── defaults/
│       │   └── main.yml
│       └── tasks/
│           └── main.yml
│
├── vars/
│   └── vault.yml
│
├── ansible.cfg
├── Arbol_proyecto_vista.md
├── Estructura Correo HTML.md
├── Flujo de CIS level1.md
└── RESUMEN_CAMBIANTE.md