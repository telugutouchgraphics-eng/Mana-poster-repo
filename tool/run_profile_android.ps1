$ErrorActionPreference = "Stop"

$deviceId = "10BD9E3AYT000CY"

Write-Host "Running app in profile mode on device: $deviceId"
flutter run `
  -d $deviceId `
  --profile `
  --dart-define=MANA_POSTER_SHOW_PERF_OVERLAY=true `
  --dart-define=MANA_POSTER_SHOW_RASTER_CHECKERBOARD=false `
  --dart-define=MANA_POSTER_PROFILE_FRAMES=true
