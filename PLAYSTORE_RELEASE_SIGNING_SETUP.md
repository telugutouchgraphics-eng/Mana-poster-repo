# PLAYSTORE RELEASE SIGNING SETUP

## 1. What is currently already configured in Gradle
- `android/app/build.gradle.kts` already reads `android/key.properties` (via `rootProject.file("key.properties")`).
- A `release` signing config is already defined with required keys:
  - `storeFile`
  - `storePassword`
  - `keyAlias`
  - `keyPassword`
- `buildTypes.release` already uses `release` signing when `key.properties` exists.

## 2. What is still missing
- Real `android/key.properties` file (not committed, local only).
- Real upload keystore file on your machine.
- One successful signed release build verification (`.aab` and/or `.apk`).

## 3. Exact steps to finish local release signing setup
1. Generate or locate your Play upload keystore file.
2. Place the keystore in a local Android path (recommended: `android/keystore/upload-keystore.jks`).
3. Copy `android/key.properties.example` to `android/key.properties`.
4. Fill real values in `android/key.properties` (do not commit this file).
5. Make sure `storeFile` path matches the real keystore location from Gradle app module context.
6. Build release artifacts and verify they are signed.

## 4. Where the real keystore file should be placed
- Recommended location: `android/keystore/upload-keystore.jks`
- Then set in `android/key.properties`:
  - `storeFile=../keystore/upload-keystore.jks`

## 5. How to create `android/key.properties` from `android/key.properties.example`
PowerShell:
```powershell
Copy-Item android/key.properties.example android/key.properties
```

Then edit `android/key.properties` and fill:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=YOUR_KEY_ALIAS
storeFile=../keystore/upload-keystore.jks
```

## 6. How to verify release signing without exposing secrets
1. Build release artifacts locally.
2. Confirm artifact files are created under `build/app/outputs/`.
3. Verify signature metadata only (no passwords printed):
   - APK: use `apksigner verify --print-certs <apk-path>`
   - AAB: use `jarsigner -verify -verbose -certs <aab-path>`
4. Confirm no debug signing fallback was used for the final upload artifact.

## 7. Exact commands to generate release artifacts
From project root:
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

Alternative via Gradle (inside `android` folder):
```powershell
.\gradlew bundleRelease
.\gradlew assembleRelease
```

## Ready to try signed release build
- [ ] `android/key.properties` created locally from example
- [ ] Keystore file exists at the path referenced by `storeFile`
- [ ] `storePassword`, `keyPassword`, `keyAlias`, `storeFile` all filled correctly
- [ ] `flutter build appbundle --release` succeeds
- [ ] `flutter build apk --release` succeeds
- [ ] Signature verification command passes on generated artifact(s)
- [ ] No secret file (`android/key.properties`) is committed
