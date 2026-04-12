# Mana Poster QA Status Matrix

## Current Static Verification
- `flutter analyze --no-pub`: PASS
- Portal `npm run lint`: PASS
- Portal `npm run build`: PASS
- Firestore indexes for app banners and approved posters: DEPLOYED
- Portal production deploy: PASS

## Needs Real Device Verification
- Profile save and restore after reinstall
- Approved poster visibility timing on real mobile network
- Download save in gallery
- WhatsApp share intent
- BG removed photo output on final poster
- Dynamic category visibility by actual date
- Banner render on different screen sizes

## Highest Risk Areas
- category mapping between portal category ids and app chips
- user profile photo remote/local fallback behavior
- creator poster personalization consistency
- slow network cache behavior

## Recommended Test Order
1. Profile save
2. Creator upload
3. Manager approve
4. App refresh
5. Category filter
6. Banner sync
7. Download/share
8. Reinstall + restore

