# PLAYSTORE LOCAL RELEASE VERIFICATION

## 1. Preconditions before build
- [ ] `android/key.properties` exists locally (not committed)
- [ ] `android/key.properties` has non-empty values for:
  - `storePassword`
  - `keyPassword`
  - `keyAlias`
  - `storeFile`
- [ ] Keystore file exists at the path referenced by `storeFile`
- [ ] `git status` does not show signing secrets staged for commit

## 2. Exact commands to run
From project root:
```powershell
flutter clean
flutter pub get
flutter build appbundle --release
flutter build apk --release
```

Signature checks (replace paths if needed):
```powershell
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
```

## 3. What output files should be generated
- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

## 4. What evidence to capture after build
- Build command result: success (no signing error)
- Exact generated artifact paths
- Signature verification output snippets for both AAB and APK
- Confirmation that no debug signing was used

## 5. How to confirm the build is signed with release config and not debug fallback
- `flutter build ... --release` completes successfully with local `key.properties` present.
- `jarsigner`/`apksigner` verification shows a valid cert for the generated artifact.
- Cert details must match your upload keystore identity (not Android debug cert).
- If cert subject looks like default debug cert, treat as fail.

## 6. Common failure cases to watch for
- `android/key.properties` missing
- Wrong `storeFile` path in `android/key.properties`
- Wrong keystore password / key password / alias
- Keystore file exists but unreadable
- `jarsigner` or `apksigner` not installed in local environment
- Build succeeds but verification shows debug cert

## 7. Final pass/fail checklist
- [ ] AAB build succeeded
- [ ] APK build succeeded
- [ ] AAB signature verified
- [ ] APK signature verified
- [ ] Verified cert is upload/release cert, not debug cert
- [ ] No signing secrets are tracked by git

Result:
- PASS = all boxes checked
- FAIL = any box unchecked

## 8. Paste back to ChatGPT
Paste exactly:
```text
Release verification result: PASS/FAIL

Artifacts:
- AAB: <full path>
- APK: <full path>

Signature check summary:
- AAB jarsigner result: <short output line>
- APK apksigner result: <short output line>
- Cert subject/identity seen: <value>
- Debug cert detected: YES/NO

Git safety check:
- key.properties tracked or staged: YES/NO
- keystore tracked or staged: YES/NO

Any errors:
- <error 1 or NONE>
- <error 2 or NONE>
```
