$ErrorActionPreference = "Stop"

$projectId = "mana-poster-ap"
$region = "asia-south1"
$serviceName = "mana-poster-rembg"
$bucket = "mana-poster-ap.firebasestorage.app"
$serviceDir = "cloud_run/rembg_service"
$gcloud = "$env:LOCALAPPDATA\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd"

if (-not (Test-Path $gcloud)) {
  throw "gcloud not found at: $gcloud"
}

Write-Host "Using gcloud: $gcloud"
& $gcloud config set project $projectId

Write-Host "Ensuring required APIs are enabled..."
& $gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com iamcredentials.googleapis.com

Write-Host "Deploying Cloud Run service..."
& $gcloud run deploy $serviceName `
  --source $serviceDir `
  --region $region `
  --platform managed `
  --allow-unauthenticated `
  --memory 2Gi `
  --cpu 2 `
  --timeout 300 `
  --set-env-vars "FIREBASE_STORAGE_BUCKET=$bucket,REMBG_MODEL=u2net_human_seg,MAX_INPUT_BYTES=20971520,ALLOW_ORIGIN=*,REMBG_ALPHA_MATTING=true,REMBG_ALPHA_FG_THRESHOLD=240,REMBG_ALPHA_BG_THRESHOLD=12,REMBG_ALPHA_ERODE_SIZE=8"

$url = & $gcloud run services describe $serviceName --region $region --format "value(status.url)"
Write-Host ""
Write-Host "Cloud Run URL: $url"
Write-Host "Use this Flutter define:"
Write-Host "--dart-define=MANA_POSTER_REMOVE_BG_API_URL=$url/remove-bg"
