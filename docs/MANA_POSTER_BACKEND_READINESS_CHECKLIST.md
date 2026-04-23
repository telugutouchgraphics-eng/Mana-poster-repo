# Mana Poster Backend Readiness Checklist

Use this checklist before staging review or controlled production rollout.

## Core Backend

- [ ] Firebase project selected and verified.
- [ ] Firebase Authentication enabled.
- [ ] Email/Password sign-in enabled.
- [ ] First admin user created.
- [ ] Admin custom claim `admin: true` assigned.
- [ ] Admin token refreshed after claim assignment.

## Authorization

- [ ] Signed-out admin route shows login.
- [ ] Non-admin signed-in user sees access denied.
- [ ] Admin user can access dashboard.
- [ ] Admin preview route is protected by the same admin gate.
- [ ] Public landing remains public.

## Firestore

- [ ] Firestore enabled.
- [ ] Rules deployed.
- [ ] `landingDrafts/main` can be created/loaded by admin.
- [ ] Draft save updates `landingDrafts/main`.
- [ ] Publish writes `landingPublished/main`.
- [ ] Public landing can read `landingPublished/main`.
- [ ] Missing/failed published read falls back safely.
- [ ] Version snapshots are created under `landingVersions`.
- [ ] Restore writes selected version back to draft only.
- [ ] `adminAuditLogs` records admin actions.

## Storage And Media

- [ ] Firebase Storage enabled.
- [ ] Storage rules deployed.
- [ ] Admin media upload writes to `landing-media/{mediaId}/{filename}`.
- [ ] Media metadata writes to `mediaLibrary/{mediaId}`.
- [ ] Public landing can read selected media URLs.
- [ ] Admin can delete media metadata and storage object.
- [ ] Storage CORS behavior is verified for web image rendering.

## Landing Content

- [ ] App links are real production values.
- [ ] Support email is real.
- [ ] Support phone is real or intentionally hidden/placeholder-free.
- [ ] Privacy Policy URL is real.
- [ ] Terms URL is real.
- [ ] Play Store URL is final.
- [ ] Real app screenshots are uploaded and selected.
- [ ] Public landing QA completed on desktop, tablet, and mobile.

## Admin Dashboard

- [ ] Draft save status is clear.
- [ ] Publish status is clear.
- [ ] Media upload/delete feedback is clear.
- [ ] Version restore confirmation works.
- [ ] Activity History loads and filters logs.
- [ ] Logout works.
- [ ] Access denied screen works for non-admin users.

## Operational Checks

- [ ] Firestore/Storage rules deployed to the correct project.
- [ ] Firebase Hosting target is correct.
- [ ] Firebase Auth authorized domains include final domains.
- [ ] No service account secrets are committed.
- [ ] Error/fallback behavior tested with restricted rules or simulated failures.
- [ ] Backend docs reviewed by the next developer/operator.

## Status

The current backend is ready for developer handoff and staging setup after the manual Firebase project configuration above is completed.
