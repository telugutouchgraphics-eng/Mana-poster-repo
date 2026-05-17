# Referral Reward Notes

## Production Rule

- A user earns 30 days free premium only after 15 referred users complete the
  Rs.149 monthly subscription.
- The referred user must apply the referral code before the paid subscription is
  verified.
- A purchase is counted only when the referral was applied before the Play
  Billing subscription start time, with a small grace window for login/apply
  race conditions.
- Each referred subscriber UID can count only once, even if they buy again.
- Self-referrals are blocked.
- The backend is the source of truth. The app only displays the referral code,
  share link, progress, and apply-code form.
- Free premium is granted from the later of:
  - current time,
  - existing referral reward expiry,
  - active paid subscription expiry.
- After a reward grant, the current cycle count resets to 0 and the next 15 paid
  referrals can grant another 30 days.

## Backend Documents

- `referralCodes/{code}` maps a referral code to the owner UID.
- `users/{uid}/referral/source` stores the referral code applied by a referred
  user.
- `referralClaims/{subscriberUid}` prevents the same subscriber from being
  counted more than once.
- `users/{uid}/referralRewards/summary` stores current cycle progress and total
  paid referral count.
- `users/{uid}/entitlements/pro` stores the reward window fields:
  - `referralRewardActive`
  - `referralRewardStartsAt`
  - `referralRewardExpiresAt`
  - `referralRewardCycleNumber`

## Safety Notes

- Applying a referral code never gives premium by itself.
- Purchase verification still validates the Play Billing token, product ID, UID
  ownership, and subscription state before any referral count is recorded.
- `completePurchase` remains controlled by the existing subscription
  verification result; referral counting does not bypass billing verification.
- If referral counting fails after a valid purchase, subscription verification
  still succeeds and the failure is logged as a warning. This avoids breaking a
  legitimate buyer because of a reward bookkeeping issue.

## App Entry Point

Profile settings now includes `Referral rewards`.

Users can:
- copy their referral code,
- share the Play Store referral link and code,
- enter a referral code received from another user,
- view current cycle progress.

On Android installs from Google Play, the app also reads the Play Install
Referrer once and applies `mp_ref` automatically after login. The manual
apply-code field remains as a safe fallback when install-referrer data is
unavailable, delayed, or blocked by the device/store environment.

## QA Checklist

1. User A opens Profile > Referral rewards and shares code/link.
2. User B signs up and applies User A's code before subscribing.
3. User B purchases the Rs.149 monthly subscription.
4. Backend creates `referralClaims/{userBuid}`.
5. User A progress increments by 1.
6. Repeat until 15 paid referrals.
7. User A entitlement becomes active with a 30-day referral reward window.
8. User B cannot be counted again for User A or another referrer.
