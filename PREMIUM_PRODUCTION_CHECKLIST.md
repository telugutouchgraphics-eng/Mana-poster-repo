# Premium Production Checklist

## 1. Play Console Products
Create one non-consumable product for each premium design.

Current product IDs used in app:
- `premium_template_political_tholi_yekadasi_copy`
- `premium_template_political_untitled_1_2`
- `premium_template_political_untitled_1`
- `premium_template_political_untitled_2`
- `premium_template_political_whatsapp_image_2024_10_02_at_6_55_35_pm`

## 2. Firebase Storage
Recommended bucket folder structure:
```text
premium_templates/
  political/
    political_tholi_yekadasi_copy/
      preview.png
      document.json
      layers/
        layer_001.png
        layer_002.png
```

## 3. Firestore
Collection:
```text
premium_templates
```

One document per template.

Required fields:
- `category`
- `isActive`
- `sortOrder`
- `titleEn`
- `titleTe`
- `titleHi`
- `priceInr`
- `productId`
- `widthPx`
- `heightPx`
- `previewStoragePath`
- `templateDocumentStoragePath`
- `layerStoragePrefix`
- `layerCount`

Optional fields:
- `fallbackProductIds`
- `previewUrl`
- `templateDocumentUrl`

## 4. Backend Endpoints
App env vars:
- `MANA_POSTER_TEMPLATE_VERIFY_URL`
- `MANA_POSTER_TEMPLATE_STATUS_URL`

Contract doc:
- [TEMPLATE_ENTITLEMENT_BACKEND_CONTRACT.md](c:/Users/telug/mana_poster/TEMPLATE_ENTITLEMENT_BACKEND_CONTRACT.md)

## 5. Firebase Publish
Generate manifests:
```powershell
python tool/publish_premium_templates.py --category political --template-id political_tholi_yekadasi_copy --title-en "Tholi Ekadasi Premium Design" --title-te "థోలి ఏకాదశి ప్రీమియం డిజైన్" --title-hi "थोली एकादशी प्रीमियम डिज़ाइन" --product-id premium_template_political_tholi_yekadasi_copy --price-inr 499 --sort-order 1
```

Publish all manifests:
```powershell
python tool/publish_all_premium_template_manifests.py --service-account "C:\\keys\\firebase-service-account.json" --bucket "your-project.appspot.com"
```

## 6. Flutter Run / Build
Example run:
```powershell
flutter run --dart-define=MANA_POSTER_TEMPLATE_VERIFY_URL=https://your-region-your-project.cloudfunctions.net/verifyTemplatePurchase --dart-define=MANA_POSTER_TEMPLATE_STATUS_URL=https://your-region-your-project.cloudfunctions.net/templateEntitlements
```

Example release build:
```powershell
flutter build appbundle --dart-define=MANA_POSTER_TEMPLATE_VERIFY_URL=https://your-region-your-project.cloudfunctions.net/verifyTemplatePurchase --dart-define=MANA_POSTER_TEMPLATE_STATUS_URL=https://your-region-your-project.cloudfunctions.net/templateEntitlements
```

## 7. Final QA
- Premium tab opens remote templates
- Buy button triggers billing
- Success unlocks only purchased design
- Restore works on reinstall
- Purchased template opens in editor
- Layer assets load from remote JSON without missing images
- Export still works

## 8. Recommended Order
1. Create Play Console products
2. Upload template assets to Firebase
3. Publish Firestore docs
4. Deploy backend verify/status endpoints
5. Run release build with dart-defines
6. Test purchase, restore, editor open, export
