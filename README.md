# Mana Poster App

Flutter mobile app for Mana Poster user experience, poster personalization, approved poster feed, dynamic categories, banner sync, and sharing/download flows.

## Project Areas

- app home feed and category experience
- approved creator poster rendering
- user profile personalization
- dynamic festival and event categories
- banner sync from portal
- poster export, share, and download flows

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
- `PORTAL_APP_WORKFLOW_QA_REPORT.md`
