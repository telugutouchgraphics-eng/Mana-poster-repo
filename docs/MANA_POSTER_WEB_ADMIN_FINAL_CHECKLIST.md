# Mana Poster Web + Admin Final Checklist

## Status

This checklist is for final frontend readiness before backend integration begins.

Current scope is:

- public landing page
- admin dashboard
- live local preview
- local draft workflow

## Landing Page Readiness

- [x] Hero, features, categories, how-it-works, showcase, FAQ, footer present
- [x] Mobile-first responsive structure exists
- [x] Smooth section navigation exists
- [x] CTA copy is app-focused
- [x] Showcase and hero support asset-path-based visuals
- [x] Footer exposes app/support/legal information structure
- [ ] Replace final placeholder screenshots with approved production screenshots
- [ ] Replace any remaining placeholder support/contact values
- [ ] Verify final copy with business/stakeholder review

## Admin Dashboard Readiness

- [x] Sidebar navigation exists for current content panels
- [x] Local editing panels exist for landing content
- [x] Media Library panel exists
- [x] App Links panel exists
- [x] Settings panel exists
- [x] Change summary exists
- [x] Draft/save/publish/revert workflow UI exists
- [x] Live preview exists with device modes
- [ ] Add backend persistence layer later
- [ ] Add role-based access later

## Links and Support Values To Finalize

- [ ] Play Store URL
- [ ] Watch Demo URL
- [ ] Privacy Policy URL
- [ ] Terms URL
- [ ] Support email
- [ ] Support phone
- [ ] WhatsApp/contact URL
- [ ] canonical website URL

## Assets and Screenshot Tasks

- [ ] Final hero screenshots exported in correct aspect ratio
- [ ] Final showcase poster assets verified
- [ ] Favicon / icons verified for web
- [ ] No broken local asset paths
- [ ] Preview uses approved screenshots instead of placeholders where available

## Legal and Compliance Checks

- [ ] Privacy Policy page/final URL confirmed
- [ ] Terms & Conditions page/final URL confirmed
- [ ] Support contact details approved
- [ ] Copyright/footer copy reviewed
- [ ] App/brand wording approved for public use

## Device QA Checks

- [ ] Desktop landing page QA
- [ ] Laptop landing page QA
- [ ] Tablet landing page QA
- [ ] Mobile landing page QA
- [ ] Desktop admin QA
- [ ] Tablet admin QA
- [ ] Mobile admin drawer and action bar QA
- [ ] Preview mode desktop/tablet/mobile QA
- [ ] No overflow, clipping, or broken wrapping in critical flows

## Navigation and Deployment Checks

- [x] Public landing route works
- [x] Admin dashboard route works
- [x] Preview-to-editor flow works locally
- [ ] Final production host/domain routing recheck
- [ ] Final deployment pipeline verification
- [ ] Browser metadata/favicon/share metadata recheck

## Backend Integration Still Pending

The following are intentionally not implemented yet:

- backend draft storage
- real save draft API
- real publish API
- auth and access control
- media upload/storage
- audit/version history
- analytics
- remote content synchronization

## Must Be Done Before Public Release

1. Finalize all real links and support values.
2. Replace all temporary asset references with approved production assets.
3. Run manual QA across supported desktop and mobile browsers.
4. Connect backend save/publish/auth flows.
5. Re-verify preview against real published output after backend integration.
6. Confirm legal pages and deployment configuration.

## Current Hand-off Readiness

Frontend is ready for:

- stakeholder demo
- content review
- UX review
- backend contract planning

Frontend is not yet ready for:

- public publishing from admin
- secure admin access
- production content operations
