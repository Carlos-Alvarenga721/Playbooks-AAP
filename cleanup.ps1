$path = 'c:\Users\ialva\Desktop\UDB CICLOS\AAP PLAYBOOKS'
$exclude = @('.git', '.github', 'cleanup.ps1')
Get-ChildItem -Path $path -Force | Where-Object { $_.Name -notin $exclude } | Remove-Item -Recurse -Force
Write-Host 'Cleanup done'
