# PLAYSTORE RELEASE SIGNING SAFETY

## 1. Which ignore files were checked
- `.gitignore` (project root)
- `android/.gitignore`

## 2. Which rules already existed
- `android/key.properties`
  - Already present in `.gitignore` as `/android/key.properties`
  - Already present in `android/.gitignore` as `key.properties`
- `*.jks`
  - Already present in `android/.gitignore` as `**/*.jks`
- `*.keystore`
  - Already present in `android/.gitignore` as `**/*.keystore`

## 3. Which rules were added
- Added to `.gitignore`:
  - `/android/keystore/`

## 4. Whether signing secrets now appear protected from accidental commit
- Yes, based on current repo ignore rules:
  - `android/key.properties` is ignored
  - `android/keystore/` is ignored
  - `.jks` and `.keystore` files under `android/` are ignored

## 5. Remaining manual caution for the developer
- Keep real `android/key.properties` local only and never commit it.
- Keep keystore files only in ignored paths (recommended: `android/keystore/`).
- Before commit, run `git status` and confirm no signing files are staged.
- If keystore/signing files were ever committed earlier, rotate credentials/keys as needed.
