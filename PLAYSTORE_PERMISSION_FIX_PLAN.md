# PLAYSTORE PERMISSION FIX PLAN

## 1. Short summary of permission-related Play Store risks
Current Play review risk is mainly from legacy storage permissions and how media/notification access is requested.  
Highest risk areas are `READ_EXTERNAL_STORAGE` and `WRITE_EXTERNAL_STORAGE` (legacy broad storage), followed by medium-risk scrutiny on `READ_MEDIA_IMAGES` and `POST_NOTIFICATIONS` UX/justification.  
`INTERNET` and `ACCESS_NETWORK_STATE` are low-risk but should still be justified clearly in Play Console disclosures.

## 2. Permission fix table
| Permission | Current purpose | Risk | Recommended action | Exact code/files likely affected |
|---|---|---|---|---|
| `android.permission.WRITE_EXTERNAL_STORAGE` (`maxSdkVersion=28`) | Legacy save/export to gallery on very old Android | Medium | `REMOVE` (or `REPLACE` only if legacy support must continue) | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml), [home_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\home_screen.dart), [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart) |
| `android.permission.READ_EXTERNAL_STORAGE` (`maxSdkVersion=32`) | Legacy gallery/media read for Android <= 12 via `Permission.storage` | Medium | `REPLACE` with modern picker/MediaStore-oriented flow | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml), [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart), [home_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\home_screen.dart), [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart) |
| `android.permission.READ_MEDIA_IMAGES` | User image pick/edit workflows | Medium | `KEEP` now, tighten request timing and use least-privilege picker paths where possible | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml), [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart), [poster_profile_details_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\poster_profile_details_screen.dart), [image_editor_screen.dart](C:\Users\telug\mana_poster\lib\features\image_editor\screens\image_editor_screen.dart) |
| `android.permission.POST_NOTIFICATIONS` | Push reminders and updates | Medium | `KEEP` as optional; ensure clear user-facing benefit and non-blocking flow | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml), [permission_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\permission_service.dart), [notification_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\notification_service.dart), [permissions_screen.dart](C:\Users\telug\mana_poster\lib\features\prehome\screens\permissions_screen.dart) |
| `android.permission.ACCESS_NETWORK_STATE` | Network-aware behavior for online app/SDK flows | Low | `KEEP` (re-validate if removed in future hardening) | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml) |
| `android.permission.INTERNET` | All online core features (auth, remote data, storage, messaging, billing verification) | Low | `KEEP` | [AndroidManifest.xml](C:\Users\telug\mana_poster\android\app\src\main\AndroidManifest.xml), [notification_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\notification_service.dart), [subscription_backend_service.dart](C:\Users\telug\mana_poster\lib\features\image_editor\services\subscription_backend_service.dart), [template_entitlement_backend_service.dart](C:\Users\telug\mana_poster\lib\features\prehome\services\template_entitlement_backend_service.dart) |

## 3. Prioritized fix order (safest/easiest -> highest impact)
1. Validate and document optional notification flow (`POST_NOTIFICATIONS`) for Play reviewer clarity.
2. Confirm low-risk network permissions (`INTERNET`, `ACCESS_NETWORK_STATE`) with concise Play disclosure wording.
3. Remove `WRITE_EXTERNAL_STORAGE` if legacy Android <= 9 support is not required.
4. Replace `READ_EXTERNAL_STORAGE` usage path (`Permission.storage`) with modern media access approach for legacy-compatible flows.
5. Tighten `READ_MEDIA_IMAGES` requests to only on-demand points and keep denial-friendly UX.

## 4. Implementation plan
1. Generate release merged manifest and verify actual final permission set (including transitive/plugin additions).
2. Add/update a permission test checklist for Android 13+, 12, and (if supported) <= 9 save flows.
3. Implement and test removal of `WRITE_EXTERNAL_STORAGE`; verify export/save still works on supported API levels.
4. Refactor legacy `Permission.storage` branches in shared permission/export paths.
5. Re-test profile image pick, editor import, and gallery export end-to-end after storage changes.
6. Update Play Console permission and Data Safety justifications to match final behavior.
7. Re-run internal testing build and confirm reviewer notes reflect actual permission prompts.
