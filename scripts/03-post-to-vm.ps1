$ErrorActionPreference = "Stop"

Write-Host "Checking VM power state..."

$vmState = az vm get-instance-view `
  --resource-group $env:VM_RG `
  --name $env:VM_NAME `
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].code" `
  -o tsv

Write-Host "VM State: $vmState"

if ($vmState -ne "PowerState/running") {
    Write-Host "VM not running. Skipping update."
    exit 0
}

Write-Host "Updating Logstash keystore..."

az vm run-command invoke `
  --resource-group $env:VM_RG `
  --name $env:VM_NAME `
  --command-id RunShellScript `
  --scripts "
    echo '$($env:NEW_SECRET_VALUE)' | \
    /usr/share/logstash/bin/logstash-keystore add client_secret --stdin --force
    systemctl restart logstash
  "

Write-Host "VM updated successfully."