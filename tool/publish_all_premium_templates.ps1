param(
  [Parameter(Mandatory = $true)]
  [string]$ServiceAccount,

  [Parameter(Mandatory = $true)]
  [string]$Bucket
)

$ErrorActionPreference = "Stop"

Write-Host "Publishing all premium template manifests..." -ForegroundColor Cyan
python tool/publish_all_premium_template_manifests.py `
  --service-account $ServiceAccount `
  --bucket $Bucket

Write-Host "Done." -ForegroundColor Green
