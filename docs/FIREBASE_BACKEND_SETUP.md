# Mana Poster Firebase Backend Setup

This document explains the Firebase setup needed for the Mana Poster public landing page and admin dashboard backend.

## Firebase Services Required

- Firebase Authentication
- Cloud Firestore
- Firebase Storage
- Flutter web + Android Firebase app configuration

Cloud Functions are not required for the current implementation, but they are recommended later for role management, stronger audit handling, and automation.

## Platform Config Files

Verify these files are generated from the correct Firebase project:

- `lib/firebase_options.dart`, if FlutterFire CLI is used in this project
- `android/app/google-services.json`
- web Firebase config in `web/index.html` or generated FlutterFire options, depending on the active setup

Do not commit real service account JSON files into the app repository.

## Authentication Setup

1. Open Firebase Console.
2. Go to `Authentication`.
3. Enable `Email/Password` sign-in.
4. Create the first admin user with email/password.
5. Assign the custom claim `admin: true` from a trusted Admin SDK environment.

Example Admin SDK claim assignment:

```js
const admin = require("firebase-admin");

admin.initializeApp();

await admin.auth().setCustomUserClaims("FIREBASE_AUTH_USER_UID", {
  admin: true,
});
```

After assigning claims, the user must refresh their token by signing out/in or using the dashboard retry check.

## Firestore Setup

Enable Cloud Firestore in production mode.

Current backend collections:

- `landingDrafts/main`: editable admin draft
- `landingPublished/main`: public published landing content
- `landingVersions/{versionId}`: publish snapshots for restore
- `mediaLibrary/{mediaId}`: media metadata
- `adminAuditLogs/{logId}`: admin activity history

Public app collections used elsewhere in the project should remain governed by the existing rules in `firestore.rules`.

## Firebase Storage Setup

Enable Firebase Storage.

Current admin media path:

```text
landing-media/{mediaId}/{filename}
```

Storage metadata is tracked in Firestore under `mediaLibrary/{mediaId}`.

## Web Authorized Domains

In Firebase Authentication, add the final web domains under authorized domains:

- `manaposter.in`
- `www.manaposter.in`
- `admin.manaposter.in`
- Firebase Hosting preview/default domains used for testing

## First Admin Test

1. Deploy the app to a staging Firebase Hosting target.
2. Open the public landing route while signed out. It should load without admin login.
3. Open the admin route. It should show the login screen.
4. Sign in as a user without `admin: true`. It should show access denied.
5. Assign `admin: true`, refresh token, and sign in again.
6. Dashboard should load.

## Feature Tests

Run these after setup:

- Save draft and verify `landingDrafts/main` updates.
- Publish and verify `landingPublished/main` updates.
- Publish and verify `landingVersions/{versionId}` is created.
- Upload media and verify Storage object plus `mediaLibrary/{mediaId}`.
- Delete media and verify metadata/storage cleanup.
- Restore a version and verify draft changes but published content remains unchanged until next publish.
- Open Activity History and verify logs appear in `adminAuditLogs`.
- Open public landing and verify it reads published content with fallback behavior if Firestore fails.
