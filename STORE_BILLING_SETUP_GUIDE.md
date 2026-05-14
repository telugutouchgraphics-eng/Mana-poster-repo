# Store Billing Setup Guide (₹4 Trial + ₹149 Monthly Pro)

## 1. Product ID
- Use same ID everywhere: `mana_poster_premium_monthly_149`
- Code reference: `PurchaseProductIds.premiumMonthly149`

## 2. Android (Google Play Console)
1. Open app in Play Console
2. Go to `Monetize > Products > Subscriptions`
3. Create subscription with ID `mana_poster_premium_monthly_149`
4. Set trial/intro offer: `₹4` for `3 days`
5. Set recurring price: `₹149 / month`
6. Activate subscription
7. Add license testers (`Settings > License testing`)
8. Upload internal testing build and install from Play

## 3. iOS (App Store Connect)
1. Open app in App Store Connect
2. Go to `In-App Purchases`
3. Create auto-renewable subscription ID `mana_poster_premium_monthly_149`
4. Set duration: monthly
5. Set trial/intro offer: `₹4` for `3 days`
6. Set recurring price: `₹149 / month`
7. Set localizations + pricing
8. Add sandbox test users
9. Test via TestFlight/sandbox

## 4. App-side Validation
- `Upgrade` flow should return success and mark user as Pro
- `Restore` should enable Pro for existing subscribers
- Free export => watermark visible
- Pro export => no watermark

## 5. Common Failure Fixes
- Product not found:
  - ID mismatch between app and store
  - product not active
- Billing unavailable:
  - Play services/account issue
  - App installed outside store test track
- Restore not working:
  - use same store account/sandbox tester
  - verify subscription status is active
