# Go-Live Checklist

## Pre-Release
- [x] `flutter analyze` passes
- [x] `flutter test` passes
- [ ] Export with watermark works on real device
- [ ] Export without watermark works for Pro on real device
- [ ] Share flow works from export snackbar
- [ ] Upgrade and Restore flows validated with tester accounts
- [ ] Telugu copy reviewed in paywall/export messages

## Store Readiness
- [ ] Subscription `pro_monthly_20` active in store
- [ ] Price set to Rs.20/month
- [ ] Internal testers configured
- [ ] Privacy policy / terms links prepared

## Device Billing Validation (Required)
- [ ] Install app from Internal Testing track (not debug install)
- [ ] Login with tester Play/App Store account
- [ ] Open editor -> Export -> choose `Upgrade`
- [ ] Complete purchase and verify Pro activated immediately
- [ ] Export once and confirm watermark is removed
- [ ] Reinstall app / clear app data, then tap `Restore`
- [ ] Verify restored Pro state and watermark-free export again
- [ ] Test `Free with Watermark` path and verify watermark appears

## Release Build
- [ ] Android signing config verified
- [ ] iOS signing/provisioning verified
- [ ] Release notes prepared
- [ ] App version/build number bumped

## Post-Release Monitoring
- [ ] Track purchase success/failure ratio
- [ ] Track export fail events
- [ ] Track restore usage
- [ ] Watch crashes and ANR for first 48 hours
