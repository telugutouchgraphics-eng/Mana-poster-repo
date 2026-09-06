# Mana Poster Project Rules & Guidelines

## 1. Automatic 18-Language Localization (MANDATORY)

Whenever adding, updating, or refactoring ANY user-facing text, button label, dialog, toast, SnackBar, title, subtitle, confirmation popup, bottom sheet, tooltip, or error message in this Flutter application:

- **NEVER hardcode raw strings** directly in widgets or screens.
- **NEVER provide only Telugu and/or English**.
- **DO NOT wait for or ask the user to request localization.** Automatic 18-language localization is the mandatory default for ALL UI work.
- **ALWAYS implement complete localization across ALL 18 supported languages** using `context.strings.localized(...)` or equivalent methods in `AppStrings` (`lib/app/localization/app_language.dart`).

### The 18 Supported Languages:
1. `telugu` (తెలుగు)
2. `english` (English)
3. `hindi` (हिन्दी)
4. `tamil` (தமிழ்)
5. `kannada` (ಕನ್ನಡ)
6. `malayalam` (മലയാളം)
7. `marathi` (मराठी)
8. `gujarati` (ગુજરાતી)
9. `bengali` (বাংলা)
10. `punjabi` (ਪੰਜਾਬੀ)
11. `odia` (ଓଡ଼ିଆ)
12. `assamese` (অসমীয়া)
13. `konkani` (कोंकणी / Konkani)
14. `nepali` (नेपाली)
15. `meitei` (মৈতৈলোন্ / Manipuri)
16. `mizo` (Mizo ṭawng)
17. `kashmiri` (कॉशुर / Kashmiri)
18. `ladakhi` (ལ་དྭགས་སྐད་ / Ladakhi)

### Required Code Pattern:
```dart
context.strings.localized(
  telugu: '...',
  english: '...',
  hindi: '...',
  tamil: '...',
  kannada: '...',
  malayalam: '...',
  marathi: '...',
  gujarati: '...',
  bengali: '...',
  punjabi: '...',
  odia: '...',
  assamese: '...',
  konkani: '...',
  nepali: '...',
  meitei: '...',
  mizo: '...',
  kashmiri: '...',
  ladakhi: '...',
)
```

## 2. Code Quality & Verification
- Translations should be contextually natural, polite, and culturally appropriate in each language.
- Run `flutter analyze lib/` to ensure zero compilation or analyzer errors after UI edits.

## 3. Concise Communication (MANDATORY)
- Always keep responses to the user concise and to the point, strictly within a maximum of 5 lines, unless the user explicitly asks for detailed explanations or code snippets.
- Respond in natural, polite Telugu by default.

