$ErrorActionPreference = "Stop"

Write-Host "Checking Entra App secret expiry..."

$creds = az ad app credential list `
  --id $env:TARGET_APP_OBJECT_ID `
  | ConvertFrom-Json

$rotate = $false
$now = Get-Date

if (-not $creds -or $creds.Count -eq 0) {
    Write-Host "No existing secrets found."
    $rotate = $true
}
else {
    foreach ($cred in $creds) {
        $expiry = Get-Date $cred.endDateTime
        $daysLeft = ($expiry - $now).Days

        Write-Host "Secret expires in $daysLeft days"

        if ($daysLeft -le 30) {
            $rotate = $true
        }
    }
}

if (-not $rotate) {
    Write-Host "No rotation required."
    "NEW_SECRET_CREATED=false" >> $env:GITHUB_ENV
    exit 0
}

Write-Host "Rotating Entra App secret..."

$endDate = (Get-Date).AddDays(90).ToString("yyyy-MM-dd")

$newSecret = az ad app credential reset `
  --id $env:TARGET_APP_OBJECT_ID `
  --append `
  --end-date $endDate `
  --query password `
  -o tsv

if (-not $newSecret) {
    throw "Secret creation failed."
}

Write-Host "Secret created successfully."

"NEW_SECRET_CREATED=true" >> $env:GITHUB_ENV
"NEW_SECRET_VALUE=$newSecret" >> $env:GITHUB_ENV
"NEW_SECRET_EXPIRY=$((Get-Date).AddDays(90).ToString("yyyy-MM-ddTHH:mm:ssZ"))" >> $env:GITHUB_ENV