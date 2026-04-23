# Website Seed Fill Guide

Edit [landing-page-firestore-seed.json](/C:/Users/telug/mana_poster/docs/landing-page-firestore-seed.json) and replace only these placeholder values:

- `REPLACE_WITH_PLAY_STORE_OR_APP_DOWNLOAD_URL`
- `REPLACE_WITH_YOUTUBE_OR_DEMO_VIDEO_URL`
- `REPLACE_WITH_FACEBOOK_PAGE_URL`
- `REPLACE_WITH_INSTAGRAM_PAGE_URL`
- `REPLACE_WITH_YOUTUBE_CHANNEL_URL`
- `REPLACE_WITH_REAL_POSTER_IMAGE_URL_1`
- `REPLACE_WITH_REAL_POSTER_IMAGE_URL_2`
- `REPLACE_WITH_REAL_POSTER_IMAGE_URL_3`

Poster rules:
- `id` unique ga undali
- `imageUrl` public `https://` URL undali
- `sortOrder` small number nunchi start avvali
- live chupinchali ante `active: true` undali

Seed command:
```powershell
npm --prefix functions run seed:website
```

If Firestore lo old website posters remove chesi seed file unna posters maatrame unchali ante:
```powershell
node tool/seed_website_content.js --replace-posters
```
