# Store Billing Setup Guide (₹20 Monthly Pro)

## 1. Product ID
- Use same ID everywhere: `pro_monthly_20`
- Code reference: `PurchaseProductIds.proMonthly20`

## 2. Android (Google Play Console)
1. Open app in Play Console
2. Go to `Monetize > Products > Subscriptions`
3. Create subscription with ID `pro_monthly_20`
4. Set price: `₹20 / month`
5. Activate subscription
6. Add license testers (`Settings > License testing`)
7. Upload internal testing build and install from Play

## 3. iOS (App Store Connect)
1. Open app in App Store Connect
2. Go to `In-App Purchases`
3. Create auto-renewable subscription ID `pro_monthly_20`
4. Set duration: monthly
5. Set localizations + pricing
6. Add sandbox test users
7. Test via TestFlight/sandbox

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
