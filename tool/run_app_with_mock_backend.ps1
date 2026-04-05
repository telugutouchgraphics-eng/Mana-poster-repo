$ErrorActionPreference = "Stop"

Write-Host "Starting mock subscription backend..."
$backend = Start-Process -FilePath "dart" -ArgumentList @(
  "run",
  "tool/subscription_backend_mock.dart"
) -PassThru -WindowStyle Hidden

Start-Sleep -Seconds 2

try {
  Write-Host "Running Flutter app with backend dart-defines..."
  flutter run `
    --dart-define=MANA_POSTER_SUBSCRIPTION_VERIFY_URL=http://127.0.0.1:8787/api/subscription/verify `
    --dart-define=MANA_POSTER_SUBSCRIPTION_STATUS_URL=http://127.0.0.1:8787/api/subscription/status
}
finally {
  if ($backend -and !$backend.HasExited) {
    Write-Host "Stopping mock backend..."
    Stop-Process -Id $backend.Id -Force
  }
}
