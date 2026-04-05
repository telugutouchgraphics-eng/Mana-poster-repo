# Firebase Storage + Cloud Run (`rembg`) Setup

This project now supports cloud background removal with this flow:

1. Flutter app uploads input image to Firebase Storage (`users/<uid>/rembg_jobs/.../input.jpg`)
2. App calls Cloud Run API (`/remove-bg`) with Firebase ID token + input/output paths
3. Cloud Run runs open-source `rembg`, writes transparent PNG to Firebase Storage
4. Cloud Run returns download URL
5. App downloads result PNG and updates selected layer

If cloud service is unavailable, app automatically falls back to on-device MLKit/offline pipeline.

## 1) One-time prerequisites (manual)

1. Install and login:
   - `gcloud auth login`
   - `gcloud auth application-default login`
   - `firebase login`
2. Set project:
   - `gcloud config set project mana-poster-ap`
3. Enable APIs:
   - `gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com iamcredentials.googleapis.com`
4. Ensure Firebase Storage is enabled in Firebase Console.

## 2) Deploy Firebase rules (manual)

Storage rules are added in `storage.rules`.

Run:

```bash
firebase deploy --only storage
```

## 3) Deploy Cloud Run rembg service (manual)

From repo root:

```bash
gcloud run deploy mana-poster-rembg \
  --source cloud_run/rembg_service \
  --region asia-south1 \
  --platform managed \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 300 \
  --set-env-vars FIREBASE_STORAGE_BUCKET=mana-poster-ap.firebasestorage.app,REMBG_MODEL=u2net_human_seg,MAX_INPUT_BYTES=20971520,ALLOW_ORIGIN=*,REMBG_ALPHA_MATTING=true,REMBG_ALPHA_FG_THRESHOLD=240,REMBG_ALPHA_BG_THRESHOLD=12,REMBG_ALPHA_ERODE_SIZE=8
```

After deploy, copy service URL (example: `https://mana-poster-rembg-xxxxx-uc.a.run.app`).

Your API endpoint is:

`<SERVICE_URL>/remove-bg`

Optional (scripted deploy after login):

```powershell
powershell -ExecutionPolicy Bypass -File tool/deploy_rembg_backend.ps1
```

## 4) Run/build Flutter app with endpoint (manual)

For debug run:

```bash
flutter run \
  --dart-define=MANA_POSTER_REMOVE_BG_API_URL=<SERVICE_URL>/remove-bg
```

For release build:

```bash
flutter build appbundle \
  --dart-define=MANA_POSTER_REMOVE_BG_API_URL=<SERVICE_URL>/remove-bg
```

## 5) Validation checklist

1. Login user in app (Firebase Auth).
2. Open editor and select photo layer.
3. Tap `Remove BG`.
4. Check Firebase Storage:
   - `users/<uid>/rembg_jobs/.../output.png` exists.
5. App should show result with engine label: `Cloud rembg (open-source)`.

## Notes

- `rembg` is open-source; Cloud Run itself is pay-as-you-go with free tier.
- If Cloud Run fails or endpoint is not configured, app falls back to on-device flow.
- Keep endpoint secret management in CI/CD for production builds (instead of hardcoding).
