# Template Entitlement Backend Contract

## Environment Variables Used By App
- `MANA_POSTER_TEMPLATE_VERIFY_URL`
- `MANA_POSTER_TEMPLATE_STATUS_URL`

## Verify Purchase Endpoint
### Request
`POST {MANA_POSTER_TEMPLATE_VERIFY_URL}`

JSON body:
```json
{
  "platform": "android",
  "templateId": "political_tholi_yekadasi_copy",
  "productId": "premium_template_political_tholi_yekadasi_copy",
  "verificationSource": "google_play",
  "serverVerificationData": "...",
  "localVerificationData": "...",
  "transactionId": "...",
  "transactionDate": "...",
  "purchaseStatus": "purchased",
  "uid": "firebase-user-id"
}
```

### Response
```json
{
  "message": "verified",
  "unlockedTemplateIds": [
    "political_tholi_yekadasi_copy"
  ]
}
```

## Fetch Entitlements Endpoint
### Request
`POST {MANA_POSTER_TEMPLATE_STATUS_URL}`

JSON body:
```json
{
  "platform": "android",
  "uid": "firebase-user-id"
}
```

### Response
```json
{
  "message": "ok",
  "unlockedTemplateIds": [
    "political_tholi_yekadasi_copy",
    "political_untitled_1"
  ]
}
```

## App Behavior
- verify success అయితే response లో వచ్చిన `unlockedTemplateIds` మాత్రమే local ga unlock అవుతాయి
- status success అయితే app startup లో response ids local entitlement cache లో merge అవుతాయి
- response లో `unlockedTemplateIds` లేకపోతే fallback ga `templateIds` కూడా app read చేస్తుంది

## Recommended Backend Rules
- Firebase Auth bearer token verify చేయాలి
- `uid` against purchase owner check చేయాలి
- productId and templateId mapping server side verify చేయాలి
- duplicate purchase/replay requests idempotent ga handle చేయాలి
- only active templates ids మాత్రమే return చేయాలి
