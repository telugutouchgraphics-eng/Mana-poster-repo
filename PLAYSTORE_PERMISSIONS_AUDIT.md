# PLAYSTORE PERMISSIONS AUDIT

Scope: based on repository files only (`android/app/src/*/AndroidManifest.xml` and Flutter code usage).  
Strict note: dependency-merged manifest permissions are not directly visible in this repo snapshot and are marked where uncertain.

## android.permission.INTERNET
1. Permission name: `android.permission.INTERNET`
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- Also declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\debug\AndroidManifest.xml) and [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\profile\AndroidManifest.xml)
- Used by networked features in app/services (Firebase auth/firestore/storage/messaging, cloud functions, image download via `HttpClient`)
3. Why the app uses it:
- Required for login, remote data/template/banner loading, push token sync, subscription verification, cloud storage, sharing flows that depend on remote assets
4. Whether it is essential for core functionality:
- Yes
5. Whether it may create Play Store review risk:
- Low
6. Safer alternative if any exists:
- No practical alternative for this app’s online architecture
7. Recommendation: `KEEP`

## android.permission.ACCESS_NETWORK_STATE
1. Permission name: `android.permission.ACCESS_NETWORK_STATE`
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- No direct runtime request in Flutter code (normal permission)
3. Why the app uses it:
- Network-aware behavior for SDKs/plugins and app online flows (effective use is indirect)
4. Whether it is essential for core functionality:
- Likely useful but not strictly core in isolation
5. Whether it may create Play Store review risk:
- Low
6. Safer alternative if any exists:
- Could remove only after full regression test of connectivity-dependent SDK/plugin behavior
7. Recommendation: `KEEP` (current state)

## android.permission.POST_NOTIFICATIONS
1. Permission name: `android.permission.POST_NOTIFICATIONS`
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- Requested in [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart) and [notification_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\notification_service.dart)
3. Why the app uses it:
- Push reminders, updates, and local display of FCM notifications
4. Whether it is essential for core functionality:
- No (app can still run without notifications)
5. Whether it may create Play Store review risk:
- Medium if user benefit is unclear or consent flow is aggressive
6. Safer alternative if any exists:
- Keep permission optional and allow full app use without granting it (already supported via "Later" flow)
7. Recommendation: `KEEP`

## android.permission.READ_MEDIA_IMAGES
1. Permission name: `android.permission.READ_MEDIA_IMAGES`
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- Effectively used via runtime `Permission.photos` requests in:
- [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart)
- [home_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\home_screen.dart)
- [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart)
- Gallery/image flows in profile/editor use `image_picker` and save/export flows
3. Why the app uses it:
- Pick user images for profile/poster editing and media-based poster workflows
4. Whether it is essential for core functionality:
- Essential for image personalization/editing/export use cases (not required for simple app launch/browsing)
5. Whether it may create Play Store review risk:
- Medium (media permission scrutiny)
6. Safer alternative if any exists:
- Android system photo picker flow with narrower access where possible
7. Recommendation: `KEEP` (current), with gradual hardening toward picker-first approach

## android.permission.READ_EXTERNAL_STORAGE (maxSdkVersion=32)
1. Permission name: `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion="32"`)
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- Effectively used through `Permission.storage` for Android <= 12 in [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart), [home_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\home_screen.dart), and [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart)
3. Why the app uses it:
- Backward compatibility for gallery access on older Android versions
4. Whether it is essential for core functionality:
- Essential only for legacy Android media flows (<= 12)
5. Whether it may create Play Store review risk:
- Medium (legacy broad storage access is more sensitive)
6. Safer alternative if any exists:
- Migrate legacy selection/save flows to Android Photo Picker/SAF/MediaStore patterns where feasible
7. Recommendation: `REPLACE` (legacy compatibility path should be modernized)

## android.permission.WRITE_EXTERNAL_STORAGE (maxSdkVersion=28)
1. Permission name: `android.permission.WRITE_EXTERNAL_STORAGE` (`maxSdkVersion="28"`)
2. Where it is declared or used:
- Declared in [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml)
- Legacy save/export compatibility path inferred from gallery save flows in:
- [home_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\home_screen.dart)
- [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart)
- Uncertainty: no explicit direct request for `WRITE_EXTERNAL_STORAGE` in Flutter code; behavior may be plugin/platform-mediated on old Android
3. Why the app uses it:
- Legacy Android (<= 9) write-to-gallery compatibility
4. Whether it is essential for core functionality:
- Not essential for modern Android devices; only legacy compatibility
5. Whether it may create Play Store review risk:
- Medium (legacy external write permission)
6. Safer alternative if any exists:
- MediaStore/SAF-based export without broad write storage permission
7. Recommendation: `REMOVE` (if legacy device support impact is acceptable) or `REPLACE` with modern save APIs

## 8. Action items before Play Store testing
- Generate and inspect merged release manifest (`processReleaseMainManifest`) to confirm any dependency-added permissions not visible in repo source manifests.
- Re-validate permission prompts on Android 13+ and Android 12 devices for:
- login + onboarding
- profile photo pick
- poster edit/export
- notification opt-in
- Prepare Play Console permission justifications focused on:
- media access for user-selected images
- optional notifications
- Decide policy for legacy storage permissions:
- either keep temporarily with clear compatibility rationale, or
- remove/replace after migrating remaining legacy flows
- Ensure reviewer notes explicitly say notifications and some media paths are optional (app should remain usable with denial where intended).
