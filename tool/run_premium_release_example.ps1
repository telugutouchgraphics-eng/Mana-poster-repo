param(
  [Parameter(Mandatory = $true)]
  [string]$VerifyUrl,

  [Parameter(Mandatory = $true)]
  [string]$StatusUrl
)

$ErrorActionPreference = "Stop"

flutter run `
  --dart-define=MANA_POSTER_TEMPLATE_VERIFY_URL=$VerifyUrl `
  --dart-define=MANA_POSTER_TEMPLATE_STATUS_URL=$StatusUrl
