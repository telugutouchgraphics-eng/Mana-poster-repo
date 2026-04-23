# PLAYSTORE REVIEWER ACCESS

## 1. Whether login is required
Yes. Login is required before entering the main app screens.

## 2. Whether reviewer needs a demo/test account
Demo account is not strictly required if reviewer can sign in with Google or create/login with email + password.
Provide a demo account only if your release environment restricts new sign-ups.

## 3. Exact steps for reviewer to open the app and reach the main usable screens
1. Install and open the app.
2. Wait for Splash screen (~3 seconds).
3. On first launch, select language.
4. Complete onboarding screens.
5. On Login screen, use either:
   - Continue with Google, or
   - Email + Password (login or sign-up).
6. After successful login, app opens the Permissions screen.
7. Tap `Allow` (or `Later`) to continue.
8. App opens Home screen (main usable screen).

## 4. Any permissions dialog the reviewer may see
- Photos/Media permission (for gallery image selection and poster/profile image use).
- Notifications permission (for reminder/update notifications).
- If permission was previously denied, app may ask reviewer to open system app settings.

## 5. What to do if Google Sign-In is used
- Tap `Continue with Google`.
- Select any Google account and complete consent.
- If Google Sign-In is blocked in reviewer environment, use email/password login instead.

## 6. To be filled before submission
- demo email: optional if reviewer self-signup is allowed
- demo password: optional if reviewer self-signup is allowed
- support email: `manaposter2026@gmail.com`
- privacy policy url: `https://mana-poster-ap.web.app/legal/privacy-policy.html`
- account deletion url: `https://mana-poster-ap.web.app/legal/account-deletion.html`
- OTP/login note if needed: not applicable, current repo supports Google Sign-In and email/password only
