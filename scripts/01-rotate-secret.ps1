$ErrorActionPreference = "Stop"

Write-Host "Checking Key Vault secret expiry..."

$secret = az keyvault secret show `
  --vault-name $env:KV_NAME `
  --name $env:KV_SECRET_NAME 2>$null | ConvertFrom-Json

$rotate = $false

if (-not $secret) {
    Write-Host "No existing secret found."
    $rotate = $true
}
elseif (-not $secret.attributes.expires) {
    Write-Host "Secret has no expiry."
    $rotate = $true
}
else {
    $expiry = Get-Date $secret.attributes.expires
    $daysLeft = ($expiry - (Get-Date)).Days

    Write-Host "Days left: $daysLeft"

    if ($daysLeft -le 30) {
        $rotate = $true
    }
}

if (-not $rotate) {
    Write-Host "No rotation required."
    "NEW_SECRET_CREATED=false" >> $env:GITHUB_ENV
    exit 0
}

Write-Host "Rotating Azure AD secret..."

$startDate = (Get-Date).ToUniversalTime()
$endDate = $startDate.AddDays(90)

$startString = $startDate.ToString("yyyy-MM-ddTHH:mm:ssZ")
$endString = $endDate.ToString("yyyy-MM-ddTHH:mm:ssZ")

$token = az account get-access-token `
  --resource https://graph.microsoft.com `
  --query accessToken -o tsv

$body = @{
    passwordCredential = @{
        displayName   = "rotated-by-github"
        startDateTime = $startString
        endDateTime   = $endString
    }
} | ConvertTo-Json -Depth 5

$response = Invoke-RestMethod `
  -Method POST `
  -Uri "https://graph.microsoft.com/v1.0/applications/$($env:TARGET_APP_OBJECT_ID)/addPassword" `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType "application/json" `
  -Body $body

$newSecret = $response.secretText

if (-not $newSecret) {
    throw "Secret creation failed."
}

Write-Host "Secret created successfully."

# Pass values to next steps
"NEW_SECRET_CREATED=true" >> $env:GITHUB_ENV
"NEW_SECRET_VALUE=$newSecret" >> $env:GITHUB_ENV
"NEW_SECRET_EXPIRY=$endString" >> $env:GITHUB_ENV