# Legal Publishing Guide

## Files prepared
- `web/legal/privacy-policy.html`
- `web/legal/terms-and-conditions.html`
- `web/legal/account-deletion.html`

## Publish flow
1. Run `flutter build web`
2. Deploy hosting with `firebase deploy --only hosting`
3. Open these URLs and confirm they load:
- `https://mana-poster-ap.web.app/legal/privacy-policy.html`
- `https://mana-poster-ap.web.app/legal/terms-and-conditions.html`
- `https://mana-poster-ap.web.app/legal/account-deletion.html`

## Why this matters
- Privacy Policy URL is required for Play review
- Account deletion public URL is required for apps with account creation/login
- Reviewer-safe legal URLs reduce policy rejection risk
