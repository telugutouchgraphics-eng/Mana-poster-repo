# PLAYSTORE DATA SAFETY DRAFT

Based only on current repo code and existing Play Store audit markdown files.  
If a claim is not directly provable from repo, it is marked `NEEDS CONFIRMATION`.

## 1. Data collected by the app

| Data type | What it is | Where it comes from in app | Why it is needed | Optional or required |
|---|---|---|---|---|
| Account identifiers | Firebase `uid`, user auth state | [auth_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\auth_service.dart), [splash_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\splash_screen.dart) | Authentication, user-scoped data access | Required for logged-in features |
| Email address | Email for sign-in/sign-up/reset | [auth_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\auth_service.dart), [login_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\login_screen.dart) | Account login and recovery | Required for email login path |
| Google sign-in identity token | Google OAuth ID token used for Firebase sign-in | [auth_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\auth_service.dart) | Google login | Optional (only when Google login is chosen) |
| Profile data | Display name, WhatsApp number, business name, business tagline, business WhatsApp, logo style, identity mode | [poster_profile_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\poster_profile_service.dart), [poster_profile_details_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\poster_profile_details_screen.dart) | Poster personalization and profile rendering | Mostly optional, except minimum profile defaults |
| User photos/assets | Profile photo, original profile photo, business logo files/URLs | [poster_profile_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\poster_profile_service.dart), [poster_profile_details_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\poster_profile_details_screen.dart) | Show user identity on posters | Optional |
| Push token data | FCM token, token doc id, platform, timestamps, welcome flags | [notification_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\notification_service.dart), [index.js](C:\Users\telug\mana_poster\functions\index.js) | Push notification delivery | Optional (notification permission can be denied) |
| Purchase/subscription data | Product ID, verification source/data, purchase status, transaction id/date, entitlement status | [pro_purchase_gateway.dart](C:\Users\telug\mana_poster\lib\features\image_editor\services\pro_purchase_gateway.dart), [subscription_backend_service.dart](C:\Users\telug\mana_poster\lib\features\image_editor\services\subscription_backend_service.dart), [index.js](C:\Users\telug\mana_poster\functions\index.js) | Verify paid entitlement | Optional (only for premium flow) |
| Template entitlement data | Template ID + purchase evidence payload + unlocked template IDs | [template_entitlement_backend_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\template_entitlement_backend_service.dart) | Premium template access control | Optional (premium templates only) |
| Local app preferences | Language, onboarding/permission flow flags, profile cache fields | [app_flow_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\app_flow_service.dart), [poster_profile_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\poster_profile_service.dart) | UX continuity | Required for smooth UX, stored locally |

## 2. Data shared by the app

- No explicit evidence in repo of selling or sharing user data with non-service third-party advertisers/data brokers.
- Data is transmitted to Google/Firebase services and Google Play Billing related services for app operation (auth, storage, messaging, purchases).  
- Whether this is marked as "shared" in Google Play Data Safety (vs "collected by service provider for app functionality") is `NEEDS CONFIRMATION`.

## 3. Per-data-type notes (what, source, why, optional/required)

Covered in Section 1 table above.  
Additional strict note: no explicit phone/SMS OTP flow is present in current Flutter auth service; login paths in repo are Google + Email/password.

## 4. Authentication-related data

- Email/password credentials (email path).
- Google sign-in token and Firebase auth credential (Google path).
- Firebase `uid` used as primary user identifier in Firestore/Storage paths.
- Password values are entered and sent via Firebase Auth SDK; repo does not persist raw password locally.
- Whether any auth logs/metadata are retained outside Firebase defaults is `NEEDS CONFIRMATION`.

## 5. User-generated content data

- User-entered profile/business text fields:
  - name/display name
  - WhatsApp numbers
  - business name/tagline
- User-selected media:
  - profile photo
  - original profile photo
  - business logo
- Stored locally and synced to Firebase services for signed-in users.
- No clear repo evidence of uploading final exported poster images to backend by default; exports appear local/share flow.

## 6. Device/app info collected if any

- FCM push token and platform (`android`/`ios`/`other`) are stored for notification delivery.
- `Platform.operatingSystem` is sent in subscription/template entitlement backend payloads.
- Android SDK version is read in permission handling (`device_info_plus`) to decide permission type, but no direct repo evidence it is sent to backend.
- IP address, advertising ID, or analytics IDs are `NEEDS CONFIRMATION` (not directly implemented in visible app code).

## 7. Likely Google Play Data Safety answers

Draft only (final legal/compliance sign-off required):

- **Does the app collect data?**  
  `Yes` (account data, profile/user content, purchase-related data, push token/device platform data).

- **Is data shared with third parties?**  
  `Likely No` for non-service-provider sharing; data transfer to Google/Firebase/Play services occurs for core functionality.  
  Final checkbox interpretation is `NEEDS CONFIRMATION`.

- **Is collection required for app use?**  
  Core login/account data: `Required` for logged-in app flow.  
  Notifications, media/profile customization, and premium purchase data: `Optional` by feature usage.

- **Is data encrypted in transit?**  
  `Likely Yes` (HTTPS cloud function endpoints and Firebase SDK traffic), but formal declaration is `NEEDS CONFIRMATION`.

- **Can users request deletion?**  
  `Yes` via in-app account deletion flow and public deletion information page.

- **Does app use data only for app functionality/account management/personalization?**  
  `Likely Yes` based on code paths; no ad SDK found in current audits.

## 8. Needs manual confirmation before submission

- Final legal meaning of "shared" for Firebase/Google service-provider flows in Play Data Safety.
- Exact Data Safety category mapping for:
  - WhatsApp number fields
  - push token/device platform
  - purchase verification payload fields
- Whether any dependency-level SDK adds analytics/crash/identifier collection not visible in app code.
- Whether encryption-at-rest is enabled/configured for all backend stored fields.
- Final checkbox interpretation for "data shared" vs "service provider processing".
- Final Play Console submission of privacy policy URL and support email.
