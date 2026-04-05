# Billing Device Checklist (Android/iOS)

## Store Setup
- Create product id: `pro_monthly_20`
- Ensure product is Active in store console
- App package/bundle id matches uploaded build

## Android (Play Billing)
- Upload internal testing build to Play Console
- Add tester Gmail accounts in license testing
- Install app from Play internal track (not local debug apk)

## iOS (StoreKit)
- Create subscription product in App Store Connect
- Add sandbox tester account
- Test using TestFlight/sandbox flow

## In-App Scenarios to Validate
- Purchase success -> `Pro` status updates in app
- User cancels purchase -> proper Telugu message
- Restore success -> `Pro` status restored
- Restore no purchase -> proper Telugu message
- Billing unavailable -> graceful Telugu guidance shown

## Export Validation
- Free user export shows watermark (logo + text)
- Pro user export saves without watermark
- App restart preserves pro status

## Regression Quick Check
- `flutter analyze` passes
- `flutter test` passes
