Playbooks-AAP/
│
├── playbooks/
│   ├── 00_cis_break.yml          ✅ ya existe
│   ├── 01_cis_audit.yml          ✅ ya existe
│   ├── 02_cis_remediation.yml    ✅ ya existe
│   ├── 03_cis_report.yml         ✅ ya existe
│   │
│   ├── emp_oracle_mgmt.yml       ← NUEVO (target: rhel-target)
│   └── emp_ad_mgmt.yml           ← NUEVO (target: windows-dc)
│
├── roles/
│   ├── cis_hardening/            ✅ ya existe
│   │
│   ├── oracle_users/             ← NUEVO
│   │   ├── tasks/
│   │   │   └── main.yml          ← lógica Oracle por action
│   │   └── defaults/
│   │       └── main.yml          ← defaults seguros Oracle
│   │
│   └── ad_users/                 ← NUEVO
│       ├── tasks/
│       │   └── main.yml          ← lógica AD por action
│       └── defaults/
│           └── main.yml          ← defaults seguros AD
│
├── inventories/
│   └── hosts.yml                 ← agregar rhel-target aquí
│
└── vars/
    └── vault.yml                 ✅ ya existe (agregar creds Oracle)