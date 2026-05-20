# Play Store Scan — Green Report

**App:** Mana Poster Ai (`com.manaposter.app`)  
**Version scanned:** `1.0.72+82`  
**Scan date:** 2026-05-20  
**Platform focus:** Android (Google Play)

---

## Executive summary

| Area | Status |
|------|--------|
| Code quality (`flutter analyze`) | **PASS** — 0 issues |
| Unit/widget tests | **PASS** — 10/10 |
| Debug APK build | **PASS** |
| Launcher icons (mipmap) | **PASS** — generated |
| Crash handling (Crashlytics + zone guard) | **PASS** |
| Permissions (no location/SMS/contacts) | **PASS** |
| Legal URLs live (`manaposter.in`) | **PASS** |
| AdMob GDPR consent (UMP) | **PASS** — added in this scan |
| Device coverage (ARM phones/tablets) | **PASS** |
| Play Console manual forms | **PENDING** — business/manual only |

**Verdict:** App code is **ready for signed release build + Play upload**. Finish Play Console items below before submitting to production.

---

## Automated checks (passed)

- `flutter analyze` — no issues
- `flutter test` — all tests passed
- `flutter build apk --debug` — success
- `dart run flutter_launcher_icons` — Android mipmaps created under `android/app/src/main/res/mipmap-*`

---

## Fixes applied in this scan

1. **Launcher icons** — generated missing `ic_launcher` mipmaps (was blocking clean clone builds).
2. **AdMob UMP consent** — `AdMobConsentService` runs before `MobileAds.initialize()`; banner/rewarded ads gated on `canRequestAds()`.
3. **Ad privacy choices** — Profile shows “Ad privacy choices” when UMP requires it (EEA/UK).
4. **Billing safety** — wrong SKU no longer falls back to `productDetails.first`; returns `productNotFound`.
5. **Release logs** — billing-security `debugPrint` gated to debug builds only.
6. **ProGuard** — added keep rules for Firebase, Play Billing, Flutter plugins (reduces release-only crash risk).
7. **Docs** — Play Store manual/reviewer URLs aligned to `https://manaposter.in/legal/...` (matches app config).
8. **pubspec description** — updated from placeholder text.

---

## Android / device compatibility

| Setting | Value | Notes |
|---------|-------|-------|
| minSdk | 21+ (Flutter default) | Covers ~99% active devices |
| targetSdk | 35 | Meets current Play requirement |
| compileSdk | 36 | Current |
| ABIs shipped | `arm64-v8a`, `armeabi-v7a` | Real phones/tablets only |
| x86/x86_64 | Stripped from AAB | Emulators use debug builds; Play users unaffected |

**Not supported by design:** x86-only devices (rare). ARM Android 5.0+ phones/tablets are supported.

---

## Permissions & Play policy

| Permission | Risk | Status |
|------------|------|--------|
| INTERNET, NETWORK_STATE | Low | OK |
| AD_ID | Ads declaration required | OK — UMP + declare in Console |
| POST_NOTIFICATIONS | Optional UX | OK — “Later” path exists |
| READ_MEDIA_IMAGES | Photo policy | OK — scoped to poster/profile |
| CAMERA | Profile/editor | OK |
| Location, SMS, contacts | High | **Not declared** |

---

## Crashes & stability

- Global `runZonedGuarded` + Firebase Crashlytics
- Non-fatal handling for network/image/permission errors
- Startup tasks isolated (Firebase/ads/billing failures don’t kill app)
- No `TODO`/`FIXME` or raw `print` in `lib/`

**Manual still required:** Run **signed release** AAB on 2–3 real devices (billing, export, bg removal, ads, notifications).

---

## Before you upload to Play (manual)

1. Configure release signing (`android/key.properties` or `MANA_POSTER_KEYSTORE_*` env).
2. Build: `flutter build appbundle --release` (then verify with `verifyReleaseBundleAbis` task).
3. Play Console: **Data Safety**, **Ads declaration**, **Content rating** (political content), **App category**.
4. AdMob: create **Privacy & messaging** form in AdMob console (UMP needs this for EEA).
5. Publish subscription SKUs matching `SubscriptionPlanConfig`.
6. Deploy `firestore.rules` + Cloud Functions if changed.
7. Smoke test on Android 13+ and one older device (API 26–28).

---

## Sign-off

| Check | Result |
|-------|--------|
| Code scan | **GREEN** |
| Tests | **GREEN** |
| Debug build | **GREEN** |
| Policy/code blockers fixed | **GREEN** |
| Play Console submission | **YELLOW** — complete manual checklist above |
