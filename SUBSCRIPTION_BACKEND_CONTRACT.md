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
  "productId": "mana_poster_premium_monthly_149",
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
  "message": "Entitlement active",
  "referralRewardActive": false,
  "referralRewardStartsAt": null,
  "referralRewardExpiresAt": null
}
```

Referral rewards are included in this endpoint. If the paid Play Billing
subscription is inactive but a valid referral reward window exists,
`subscriptionStatus` returns `isPro: true`, `status: "active"`,
`subscriptionState: "REFERRAL_REWARD"`, and the reward expiry as `expiryTime`.

## 3) Referral Rewards

### Rule
- 15 referred users must join with the referrer's code/link and complete the
  Rs.149 monthly subscription.
- A referred subscriber can count only once.
- Self-referrals are rejected.
- The referral must be applied before the Play Billing subscription start time,
  with a small grace window for login/apply race conditions.
- After 15 paid referrals in the current cycle, the referrer receives 30 days
  free premium.
- If the referrer already has an active paid subscription or active referral
  reward, the new free month starts after the existing active window so reward
  days are not lost.
- After a reward is granted, the cycle count resets to 0 and the next cycle can
  earn another 30 days.
- The app shares a Play Store link with `referrer=mp_ref%3D<code>` and applies
  the install referrer after login when Google Play returns it. Users can also
  apply the code manually from Profile > Referral rewards.

### Referral Status Endpoint
- Cloud Function name: `referralStatus`
- Current deployed URL:
  `https://asia-south1-mana-poster-ap.cloudfunctions.net/referralStatus`

Request:
```json
{}
```

Response:
```json
{
  "code": "MP1234567890",
  "link": "https://play.google.com/store/apps/details?id=com.manaposter.app&referrer=mp_ref%3DMP1234567890",
  "requiredPaidReferrals": 15,
  "rewardDays": 30,
  "currentCycleNumber": 1,
  "currentCyclePaidCount": 0,
  "totalPaidReferralCount": 0,
  "rewardActive": false,
  "rewardStartsAt": null,
  "rewardExpiresAt": null
}
```

### Apply Referral Code Endpoint
- Cloud Function name: `applyReferralCode`
- Current deployed URL:
  `https://asia-south1-mana-poster-ap.cloudfunctions.net/applyReferralCode`

Request:
```json
{
  "referralCode": "MP1234567890"
}
```

Response:
```json
{
  "accepted": true,
  "message": "Referral applied",
  "referralCode": "MP1234567890"
}
```

The backend counts a referral only inside the successful Play Billing
verification path. Applying a code by itself never grants premium access.

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
- `MANA_POSTER_REFERRAL_STATUS_URL`
- `MANA_POSTER_REFERRAL_APPLY_URL`

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
