# PLAYSTORE BLOCKER 01 PLAN

## 1. Blocker name
Release signing readiness not confirmed for upload build.

## 2. Why it blocks Closed Testing
Closed Testing requires a signed release artifact (AAB/APK).  
Current docs indicate local fallback to debug signing when release keystore config is missing, which is not acceptable for Play upload.

## 3. Blocker type
Config-related + manual.

## 4. Exact files or areas likely involved
- [build.gradle.kts](C:\Users\telug\mana_poster\android\app\build.gradle.kts)
- `android/key.properties` (local signing config file; currently referenced by Gradle)
- Release keystore file path referenced by `key.properties`
- Play Console app signing setup area (manual)

## 5. Smallest safe fix approach
Set up and verify a valid release keystore + `key.properties` so release build uses `signingConfigs.release` (not debug fallback), then generate one signed release artifact and validate it for Play upload.

## 6. Step-by-step implementation tasks
1. Confirm whether an official release keystore already exists.
2. If missing, generate a new release keystore with secure credentials.
3. Create/update `android/key.properties` with:
   - `storeFile`
   - `storePassword`
   - `keyAlias`
   - `keyPassword`
4. Verify `android/app/build.gradle.kts` resolves to `signingConfigs.release` when `key.properties` exists.
5. Build release artifact (`appbundle` preferred for Play).
6. Confirm artifact is signed with release key (not debug key).
7. Upload artifact to internal/closed track draft and verify Play accepts it.

## 7. What must be manually verified after the fix
- Release build no longer uses debug signing fallback.
- Generated AAB/APK is accepted by Play Console without signing errors.
- Keystore and credentials are securely stored/backed up (team-access policy).
- CI/release process can reproduce signed build reliably.
