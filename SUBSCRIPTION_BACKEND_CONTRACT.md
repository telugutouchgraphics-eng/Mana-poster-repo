# Subscription Backend Contract

This document defines the API contract expected by the app in:
`lib/features/image_editor/services/subscription_backend_service.dart`

## Auth
- Header: `Authorization: Bearer <firebase_id_token>` (optional in local mock, required in production)
- Content-Type: `application/json`

## 1) Verify Purchase

### Endpoint
- Cloud Function name: `verifySubscription`
- Example URL:
  - `https://asia-south1-<project-id>.cloudfunctions.net/verifySubscription`
  - Current deployed URL:
    `https://asia-south1-mana-poster-ap.cloudfunctions.net/verifySubscription`

### Request JSON
```json
{
  "platform": "android",
  "uid": "firebase-user-uid",
  "productId": "pro_monthly_20",
  "verificationSource": "google_play",
  "serverVerificationData": "purchase_token_or_receipt",
  "localVerificationData": "optional_local_payload",
  "transactionId": "optional_transaction_id",
  "transactionDate": "optional_unix_ms_or_iso",
  "purchaseStatus": "purchased"
}
```

### Response JSON
```json
{
  "isPro": true,
  "message": "Verification success"
}
```

## 2) Get Entitlement Status

### Endpoint
- Cloud Function name: `subscriptionStatus`
- Example URL:
  - `https://asia-south1-<project-id>.cloudfunctions.net/subscriptionStatus`
  - Current deployed URL:
    `https://asia-south1-mana-poster-ap.cloudfunctions.net/subscriptionStatus`

### Request JSON
```json
{
  "platform": "android",
  "uid": "firebase-user-uid"
}
```

### Response JSON
```json
{
  "isPro": true,
  "message": "Entitlement active"
}
```

## Error Response
Use non-2xx status with JSON body:
```json
{
  "isPro": false,
  "message": "Detailed reason"
}
```

## Dart Defines Needed By App
- `MANA_POSTER_SUBSCRIPTION_VERIFY_URL`
- `MANA_POSTER_SUBSCRIPTION_STATUS_URL`

Example:
```bash
flutter run \
  --dart-define=MANA_POSTER_SUBSCRIPTION_VERIFY_URL=https://api.example.com/api/subscription/verify \
  --dart-define=MANA_POSTER_SUBSCRIPTION_STATUS_URL=https://api.example.com/api/subscription/status
```

## Local End-to-End Mock (No external backend)
1. Run:
```powershell
powershell -ExecutionPolicy Bypass -File tool/run_app_with_mock_backend.ps1
```
2. The script starts local backend on:
   - `http://127.0.0.1:8787/api/subscription/verify`
   - `http://127.0.0.1:8787/api/subscription/status`
3. Flutter app runs with required `--dart-define` values automatically.

## Firebase Deploy (Repo Included)
This repo now includes:
- `firebase.json`
- `.firebaserc` (default project: `mana-poster-ap`)
- `firestore.rules`
- `functions/index.js`

Deploy commands:
```powershell
cd functions
npm install
cd ..
firebase deploy --only functions,firestore
```
