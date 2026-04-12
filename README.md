# mana_poster

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Subscription Backend (Local Mock)

To run app + mock subscription backend together:

```powershell
powershell -ExecutionPolicy Bypass -File tool/run_app_with_mock_backend.ps1
```

API contract:
- `SUBSCRIPTION_BACKEND_CONTRACT.md`

Live backend endpoints deployed:
- `https://asia-south1-mana-poster-ap.cloudfunctions.net/verifySubscription`
- `https://asia-south1-mana-poster-ap.cloudfunctions.net/subscriptionStatus`

## Remove BG Backend (Cloud Run + rembg)

End-to-end setup and deploy steps:
- `REMBG_BACKEND_SETUP.md`

## Deployment

Firebase + app release steps:
- `APP_DEPLOYMENT_GUIDE.md`

## QA

Real device release verification:
- `REAL_DEVICE_QA_CHECKLIST.md`
- `QA_STATUS_MATRIX.md`
