# PLAY STORE RELEASE CHECKLIST

## 1. Privacy Policy URL
- [x] Present in app config
- Current value: `https://manaposter.in/legal/privacy-policy.html`

## 2. Support Email
- [x] Present in app config
- Current value: `manaposter2026@gmail.com`

## 3. App Category
- [ ] MISSING in repo
- Suggested from current app scope: `Art & Design`

## 4. Content Rating Inputs
- [ ] MISSING formal Play Console answers
- Likely inputs from current app: no sexual content, no gambling, no location sharing, no chat/user-to-user interaction detected
- Current app does include: user-created poster/profile content, push notifications, and in-app purchases
- Review carefully because the app includes political poster content

## 5. Ads Declaration
- [x] Ads SDK detected in current dependencies and Android manifest
- Current app uses `google_mobile_ads` with banner/rewarded flows and `AD_ID` permission
- Play Console answer likely: `Yes`

## 6. Login Required or Not
- [x] Required
- Current flow blocks home access until user signs in
- Sign-in methods detected: `Google` and `Email/password`

## 7. Reviewer Demo Account Needed or Not
- [x] Not needed if Play reviewer can self-sign up with Google or email
- [ ] If sign-up is restricted outside test builds, provide a demo account

## 8. Data Safety: what user data is collected/shared
- Collected: email, Firebase UID, Google sign-in identity, poster profile name, WhatsApp number, profile photo/business logo, push token, purchase/subscription metadata
- Shared/processed by third parties: Google Firebase (`Auth`, `Firestore`, `Storage`, `Messaging`) and Google Play Billing
- [ ] MISSING final Play Console Data Safety mapping/submission

## 9. Permissions used in the app and why each permission is needed
- `INTERNET`: Firebase auth/storage/firestore, subscription verification, remote banners/templates, notification image download
- `ACCESS_NETWORK_STATE`: online feature/network status handling
- `POST_NOTIFICATIONS`: push notifications and reminders
- `READ_MEDIA_IMAGES`: pick photos from gallery on Android 13+
- `READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`): pick photos from gallery on Android 12 and below
- `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=28`): save exported posters on older Android versions

## 10. Current Target SDK
- [x] `36`

## 11. Current Version Name and Version Code
- [x] Version Name: `1.0.37`
- [x] Version Code: `44`

## 12. Missing items before Play Store testing
- [ ] Privacy policy URL
- [ ] Support email
- [ ] Final app category selection in Play Console
- [ ] Final content rating questionnaire submission
- [ ] Final Data Safety form submission
- [ ] Confirm whether reviewer instructions/demo account are needed
- [x] Release signing setup present locally via `android/key.properties`
