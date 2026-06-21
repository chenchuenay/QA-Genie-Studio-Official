# CI/CD Setup — GitHub Secrets

## Step 1: Generate base64 keystore

Run this in terminal:

```bash
base64 -i /Users/chenchuenay/qa-genie-release.jks | pbcopy
```

This copies the encoded keystore to your clipboard.

## Step 2: Generate Firebase token

```bash
firebase login:ci
```

Opens browser → sign in → copies token to clipboard.

## Step 3: Get Play Service Account JSON

1. Go to https://play.google.com/console/developers
2. Settings → API Access → Service Accounts
3. Create service account → download JSON key

## Step 4: Add secrets to GitHub

Go to: **GitHub → QA_Genie → Settings → Secrets and variables → Actions**

Add these **6 secrets**:

| Secret name | Value |
|---|---|
| `KEYSTORE_FILE_B64` | Paste from Step 1 (base64 of qa-genie-release.jks) |
| `KEYSTORE_STORE_PASSWORD` | `android` |
| `KEYSTORE_KEY_ALIAS` | `my-key-alias` |
| `KEYSTORE_KEY_PASSWORD` | `android` |
| `PLAY_SERVICE_ACCOUNT_JSON` | Paste the full JSON from Step 3 |
| `FIREBASE_TOKEN` | Paste the token from Step 2 |

## How CI/CD works after setup

| When you do this | What happens automatically |
|---|---|
| `git push` to `working` | `flutter analyze` + `flutter test` only (< 2 min) |
| `git push` to `dev` | Analyze + Test + Build **dev APK** → artifact in Actions |
| `git tag v1.2.36 && git push origin v1.2.36` on `main` | Deploy CF → Build AAB → **Upload to Play Console internal** |
| GitHub UI: Actions → `stable_fallback` → Run workflow | Build AAB from stable branch → artifact only |

## Release command (when ready)

```bash
git checkout main
git merge working
git tag v1.2.36
git push origin main --tags
```

That's it — CI/CD handles the rest.
