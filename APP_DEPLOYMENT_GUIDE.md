# Mana Poster App Deployment Guide

## 1. Firebase prerequisites
- Confirm Firebase project: `mana-poster-ap`
- Enable:
  - Authentication
  - Firestore
  - Storage
  - Cloud Functions
- Keep production `google-services.json` and `GoogleService-Info.plist` ready

## 2. Deploy Firebase backend assets
Run from [mana_poster](c:\Users\telug\mana_poster):

```powershell
firebase deploy --only firestore:rules,firestore:indexes,storage
firebase deploy --only functions
```

## 3. Firestore collections expected in production
- `creatorPosters`
- `creatorProfiles`
- `creatorInvites`
- `users`
- `creatorEarningLedger`
- `creatorPayouts`
- `competitions`
- `adminAuditLogs`
- `apiRateLimits`

## 4. App release checklist
- `flutter pub get`
- `flutter analyze --no-pub`
- Test:
  - Google login
  - profile save
  - pull-to-refresh
  - creator approved posters feed
  - download
  - WhatsApp share
  - dynamic categories
- Build Android release:

```powershell
flutter build appbundle --release
```

## 5. Production verification
- Approved creator posters appear in app home
- Dynamic categories appear on correct dates
- User profile image persists from Firestore after reinstall
- Personalized poster export keeps user photo/name/number correctly
- Firebase rules do not block poster/profile reads for valid users

## 6. Recommended next ops
- Enable Crashlytics and Analytics before public rollout
- Keep Play Console internal testing track first
- Re-run `firebase deploy --only firestore:indexes` when new queries are added
