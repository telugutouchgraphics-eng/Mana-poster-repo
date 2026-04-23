# Mana Poster Admin Authorization Setup

This project now treats Firebase Authentication as login only. Admin access is granted by a Firebase custom claim:

```json
{
  "admin": true
}
```

Only users with this claim can open the admin dashboard, save drafts, publish landing content, manage media, or restore versions.

## Access Flow

- Public landing page remains public.
- Signed-out admin route users see the admin login screen.
- Signed-in users without `admin: true` see the access denied screen.
- Signed-in users with `admin: true` can access the dashboard and admin preview flow.
- Firestore and Storage rules enforce the same claim, so UI checks are not the only security layer.

## Assign Admin Claim

Use Firebase Admin SDK from a trusted local script, Cloud Function, or secure server environment. Do not run this from the Flutter app.

```js
const admin = require("firebase-admin");

admin.initializeApp();

async function grantAdmin(uid) {
  await admin.auth().setCustomUserClaims(uid, { admin: true });
  console.log(`Admin access granted for ${uid}`);
}

grantAdmin("FIREBASE_AUTH_USER_UID");
```

To remove admin access:

```js
await admin.auth().setCustomUserClaims("FIREBASE_AUTH_USER_UID", {
  admin: false,
});
```

## Verify Claim

```js
const user = await admin.auth().getUser("FIREBASE_AUTH_USER_UID");
console.log(user.customClaims);
```

Expected output for an admin:

```json
{
  "admin": true
}
```

## Token Refresh Caveat

Custom claims are read from the Firebase ID token. After changing a claim, the user must refresh the token before the app sees the new role.

Recommended testing options:

- Sign out and sign back in.
- Use the admin access denied screen's `Check Again` action after the claim is set.
- Wait for the existing token to expire, then reload.

## Firebase Rules To Deploy

Deploy both Firestore and Storage rules after this change:

```bash
firebase deploy --only firestore:rules,storage
```

Current rule intent:

- `landingDrafts/*`: admin read/write only.
- `landingPublished/*`: public read, admin write only.
- `landingVersions/*`: admin read/write only.
- `mediaLibrary/*`: admin read/write only.
- `adminAuditLogs/*`: admin read/write only.
- `landing-media/*`: public read, admin create/update/delete only.

## Manual Test Checklist

- Open the public landing page while signed out. It should render normally.
- Open the admin route while signed out. It should show the login screen.
- Sign in with a normal non-admin Firebase user. It should show access denied.
- Grant `admin: true`, refresh token/sign in again, and open admin. It should show the dashboard.
- As admin, test draft load/save, publish, media library, and version restore.
- Remove the claim and refresh token. Admin access should be denied again.

## Still Pending

- Multi-role workflow such as editor, reviewer, and publisher.
- Granular section-level permissions.
- Audit logs for save, publish, restore, and media actions.
- Cloud Function helper to manage admin claims from a secure operations tool.
