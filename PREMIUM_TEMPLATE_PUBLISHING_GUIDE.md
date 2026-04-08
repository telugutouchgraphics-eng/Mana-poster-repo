# Premium Template Publishing Guide

## Flow
1. PSD ని `tool/import_premium_psd_templates.py` తో export చేయాలి
2. generated preview/document/layers files `assets/templates/premium/<category>/...` లో వస్తాయి
3. `tool/publish_premium_templates.py` తో Firebase manifest generate చేయాలి
4. optional ga అదే command తో Firebase Storage + Firestore publish చేయొచ్చు

## Firestore Collection
`premium_templates`

## Required Firestore Fields
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

## Example Publish Command
```powershell
python tool/publish_premium_templates.py `
  --category political `
  --template-id political_tholi_yekadasi_copy `
  --title-en "Tholi Ekadasi Premium Design" `
  --title-te "థోలి ఏకాదశి ప్రీమియం డిజైన్" `
  --title-hi "थोली एकादशी प्रीमियम डिज़ाइन" `
  --product-id premium_template_political_tholi_yekadasi_copy `
  --price-inr 499 `
  --sort-order 1
```

## Direct Firebase Publish
If you have a Firebase service account JSON and Storage bucket:
```powershell
python tool/publish_premium_templates.py `
  --category political `
  --template-id political_tholi_yekadasi_copy `
  --title-en "Tholi Ekadasi Premium Design" `
  --title-te "థోలి ఏకాదశి ప్రీమియం డిజైన్" `
  --title-hi "थोली एकादशी प्रीमियम डिज़ाइन" `
  --product-id premium_template_political_tholi_yekadasi_copy `
  --price-inr 499 `
  --sort-order 1 `
  --service-account "C:\\keys\\firebase-service-account.json" `
  --bucket "your-project.appspot.com"
```

## Notes
- `firebase-admin` package install చేసి ఉంటే direct upload పని చేస్తుంది
- install command:
```powershell
pip install firebase-admin
```
- upload చేయకుండా కూడా manifest JSON generate అవుతుంది
- generated manifest files: `tool/premium_template_manifests/`
