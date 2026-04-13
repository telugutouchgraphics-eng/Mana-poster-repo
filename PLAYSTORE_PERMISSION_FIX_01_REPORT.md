# PLAYSTORE PERMISSION FIX 01 REPORT

## 1. Which permission issue was fixed
`POST_NOTIFICATIONS` optional-flow hardening: removed automatic notification permission prompt during app startup.

## 2. Why this one was chosen first
This is the first prioritized item in `PLAYSTORE_PERMISSION_FIX_PLAN.md` and is the safest low-risk change:
- it reduces Play review friction for notification consent UX
- it does not change core app login/poster functionality
- permission can still be requested through existing permission screens

## 3. Exact files changed
- [notification_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\notification_service.dart)
- [PLAYSTORE_PERMISSION_FIX_01_REPORT.md](C:\Users\telug\mana_poster\PLAYSTORE_PERMISSION_FIX_01_REPORT.md)

## 4. What was changed
- In `NotificationService.initialize()`, removed this startup runtime call:
  - `FirebaseMessaging.instance.requestPermission(...)`
- Result:
  - app no longer triggers notification permission prompt immediately on startup
  - notification permission remains user-driven through existing app permission flow (`PermissionService` + permissions screens)

## 5. Any manual testing steps
1. Fresh install on Android 13+.
2. Launch app and verify notification permission popup does **not** appear immediately on splash/startup.
3. Complete flow until permissions screen.
4. Tap `Allow` and verify notifications permission prompt appears there.
5. Repeat and tap `Later`; verify app remains usable and reaches Home.
6. Verify push-related behavior still works after permission is granted.

## 6. Any remaining risk or follow-up
- Remaining: medium-risk legacy storage permission work (`READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`) is still pending.
- Remaining: validate final merged release manifest permissions before store upload.
- Remaining: confirm reviewer/docs wording reflects this updated notification consent behavior.
