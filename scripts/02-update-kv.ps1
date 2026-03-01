$ErrorActionPreference = "Stop"

Write-Host "Updating Key Vault secret..."

az keyvault secret set `
  --vault-name $env:KV_NAME `
  --name $env:KV_SECRET_NAME `
  --value $env:NEW_SECRET_VALUE `
  --expires $env:NEW_SECRET_EXPIRY

Write-Host "Key Vault updated successfully."