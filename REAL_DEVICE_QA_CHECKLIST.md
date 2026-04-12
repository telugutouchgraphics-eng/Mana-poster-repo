# Mana Poster Real Device QA Checklist

## Goal
- App release ki mundu real Android device meeda critical flows anni verify cheyyadam.
- Portal -> Firebase -> App sync correct ga work avuthundho confirm cheyyadam.

## Test Setup
- Production Firebase project: `mana-poster-ap`
- Portal URL: `https://mana-poster-web-portal.vercel.app`
- Test accounts:
  - admin
  - manager
  - creator
  - normal app user
- Network conditions:
  - normal Wi-Fi
  - slow mobile data

## Pass Criteria
- crash undakudadhu
- red screen / assertion error undakudadhu
- approved posters app lo correct ga kanipinchali
- profile name/photo/whatsapp poster meedha correct ga render avvali
- share/download actions real ga work avvali

## Phase 1: Auth and Access
- App user login
- Profile screen open
- Name save
- WhatsApp number save
- Photo upload
- App restart chesi profile data still undho check cheyyi
- App reinstall tarwatha remote profile restore ayindho check cheyyi

## Phase 2: Creator to App Publishing Flow
- Manager creator ki categories assign cheyyali
- Creator dashboard lo poster upload cheyyali
- Manager dashboard lo poster review list lo poster kanipinchali
- Manager approve cheyyali
- App home lo pull-to-refresh cheyyali
- Approved poster `Free` tab lo kanipinchali
- Poster latest-first order lo vastundho check cheyyi

## Phase 3: Category Mapping
- Approved poster category exact ga filter avuthundho check cheyyi
- `All` chip lo poster kanipinchali
- Assigned category chip select chesthe same poster filtered ga kanipinchali
- Emoji labels unna app categories ki backend category mapping break avvakudadhu
- Dynamic categories event dates correct ga visible avuthunnayo check cheyyi

## Phase 4: Banner Sync
- Admin dashboard lo app banner upload cheyyali
- Active ga set cheyyali
- App home open cheyyali
- Categories kinda banner kanipinchali
- Multiple banners unte sort order correct ga undali

## Phase 5: Poster Personalization
- User profile name change cheyyi
- User profile photo upload cheyyi
- BG removed photo poster meedha correct ga kanipisthundho check cheyyi
- White strip enabled templates lo user name correct ga undali
- WhatsApp number unte green strip lo number maatrame undali
- Telugu app language lo name Telugu-script lo kanipisthundho check cheyyi
- English app language lo name transliteration update avuthundho check cheyyi

## Phase 6: Home Feed UX
- App open ayyaka home load speed acceptable ga undho check cheyyi
- Pull-to-refresh smooth ga work avuthundho check cheyyi
- Search bar filtering correct ga undho check cheyyi
- Free/Premium tab switching smooth ga undho check cheyyi
- Empty states correct message chupisthunnayo check cheyyi

## Phase 7: Actions
- Download button tap cheyyi
- Gallery lo saved poster open cheyyi
- PNG/JPG output visually correct ga undho check cheyyi
- Share button tap cheyyi
- WhatsApp share intent open avuthundho check cheyyi

## Phase 8: Error Cases
- Internet off chesi app open cheyyi
- Cached approved posters still load avuthunnayo check cheyyi
- Banner unavailable ayithe home crash avvakudadhu
- Broken poster image ayithe placeholder matrame kanipinchali
- Empty category lo app stable ga undali

## Phase 9: Portal QA
- Admin login
- Manager login
- Creator login
- Creator upload preview
- Manager approve/reject
- Review comment save
- Payout page open
- Competitions page open
- App banners page open

## Sign-off
- All critical flows pass
- No crash
- No missing poster sync
- No wrong category mapping
- No stale sample text in critical user flow

