# Mana Poster Firebase Deployment Steps

Use this checklist for staging or controlled production deployment of the current backend-enabled landing/admin system.

## 1. Confirm Firebase Project

```bash
firebase use
```

Verify the active project is the intended staging or production Firebase project.

## 2. Install Flutter Dependencies

```bash
flutter pub get
```

## 3. Verify Firebase Platform Config

Confirm these are present and point to the correct Firebase project:

- Android Firebase config
- Flutter web Firebase config
- Firebase Hosting project in `.firebaserc`
- Firebase rules referenced by `firebase.json`

## 4. Deploy Firestore And Storage Rules

```bash
firebase deploy --only firestore:rules,storage
```

Rule intent:

- public can read published landing content
- only `admin: true` users can write landing/admin collections
- public can read published media assets
- only `admin: true` users can upload/delete landing media

## 5. Create First Admin User

1. Create an Authentication user with email/password.
2. Assign custom claim:

```js
await admin.auth().setCustomUserClaims(uid, { admin: true });
```

3. Sign out and sign back in after the claim is assigned.

## 6. Build Flutter Web

```bash
flutter build web --release
```

## 7. Deploy Hosting

Use the project-specific hosting target configured in `firebase.json`.

```bash
firebase deploy --only hosting
```

If the project uses multiple hosting targets, deploy the exact target configured for public/admin routing.

## 8. Smoke Test Public Landing

- Public landing opens while signed out.
- Published Firestore content loads when `landingPublished/main` exists.
- Fallback content renders if the published document is missing or invalid.
- Media URLs render from Firebase Storage.
- Footer links and app CTA values are correct.

## 9. Smoke Test Admin

- Signed-out user sees login.
- Non-admin signed-in user sees access denied.
- Admin signed-in user sees dashboard.
- Draft load works.
- Save Draft writes to `landingDrafts/main`.
- Publish writes to `landingPublished/main`.
- Publish creates `landingVersions`.
- Restore version writes back to `landingDrafts/main`.
- Media upload creates Storage object and Firestore metadata.
- Activity History shows recent admin actions.

## 10. Final Production Checks

- Firebase Auth authorized domains are correct.
- Firestore and Storage rules are deployed.
- App links, support email, phone, privacy, and terms URLs are real.
- Play Store URL is final.
- Real screenshots/media are uploaded and selected.
- Legal pages are reachable.
- Public landing works on mobile, tablet, and desktop.
- Admin dashboard is tested on desktop and at least one tablet/mobile browser.
