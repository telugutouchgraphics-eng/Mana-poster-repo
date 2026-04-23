# Mana Poster Web Public Launch Checklist

## Scope
This checklist is for public landing launch readiness of `manaposter.in` only.
Admin dashboard planning is intentionally deferred to Prompt 6.

## Content and Brand
- Verify hero headline/subtitle with final brand copy.
- Confirm category labels and FAQ wording in Telugu/English strategy.
- Confirm support email and support phone values in `AppPublicInfo`.
- Review footer legal links (privacy, terms) for correct public pages.

## Screenshot Assets
- Replace hero screenshot paths with final app screen captures if newer versions exist.
- Replace showcase image paths with approved final poster previews.
- Keep portrait ratio consistency to avoid cropping issues.
- Validate fallback visuals still look acceptable if any asset is missing.

## UX and Responsive QA
- Verify navbar scroll anchors on desktop/tablet/mobile.
- Verify section spacing rhythm at 360px, 768px, 1024px, 1440px widths.
- Check CTA button contrast and tap targets.
- Validate footer column wrapping behavior on narrow widths.

## SEO and Metadata
- Finalize title/description in `web/index.html`.
- Verify Open Graph and Twitter share preview content.
- Confirm `manifest.json` app name/description and theme color.
- Confirm favicon and icon assets are the final approved brand assets.

## Performance
- Keep screenshot files compressed and web-friendly.
- Re-run `flutter build web --release` and validate output size.
- Spot check first-load experience after hard refresh.

## Pre-deploy Verification
- Run `flutter analyze`.
- Build web release.
- Deploy public/admin hosting targets.
- Smoke test public URL and fallback web.app URL.

## Prompt 6 Starter
Prompt 6 should begin **admin dashboard planning + dashboard base UI only**.
Do not add backend/data layer in Prompt 6.
