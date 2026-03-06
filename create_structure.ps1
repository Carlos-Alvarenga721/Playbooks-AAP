$base = 'c:\Users\ialva\Desktop\UDB CICLOS\AAP PLAYBOOKS\aap-poc'

$dirs = @(
    "$base\inventories",
    "$base\roles\cis_hardening\tasks",
    "$base\roles\cis_hardening\templates",
    "$base\playbooks"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$files = @(
    "$base\inventories\hosts.yml",
    "$base\roles\cis_hardening\tasks\main.yml",
    "$base\roles\cis_hardening\templates\cis_report.html.j2",
    "$base\playbooks\01_cis_audit.yml",
    "$base\playbooks\02_cis_remediation.yml",
    "$base\playbooks\03_cis_report.yml",
    "$base\README.md"
)

foreach ($file in $files) {
    New-Item -ItemType File -Path $file -Force | Out-Null
}

Write-Host 'Structure created'
