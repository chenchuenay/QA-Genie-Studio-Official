# CI/CD Setup — GitHub Secrets

## Step 1: Generate base64 keystore

Run this in terminal:

```bash
base64 -i /Users/chenchuenay/qa-genie-release.jks | pbcopy
```

This copies the encoded keystore to your clipboard.

## Step 2: Revoke leaked token + Generate new Firebase token

The old token is now public. Revoke it first:

```bash
firebase login:ci --revoke
```

Then generate a fresh one:

```bash
firebase login:ci
```

Opens browser → sign in → copies token to clipboard.

## Step 3: Add secrets to GitHub

Go to: **GitHub → QA_Genie → Settings → Secrets and variables → Actions → Repository secrets** (not environment secrets)

Add these **5 repository secrets**:

| Secret name | Value |
|---|---|
| `KEYSTORE_FILE_B64` | Paste from Step 1 (base64 of qa-genie-release.jks) |
| `KEYSTORE_STORE_PASSWORD` | **(your keystore store password)** |
| `KEYSTORE_KEY_ALIAS` | `my-key-alias` |
| `KEYSTORE_KEY_PASSWORD` | **(your keystore key password)** |
| `FIREBASE_TOKEN` | Paste the new token from Step 2 (keep secret!) |

## How CI/CD works after setup

| When you do this | What happens automatically |
|---|---|
| `git push` to `working` | `flutter analyze` + `flutter test` only (< 2 min) |
| `git push` to `dev` | Analyze + Test + Build **dev APK** → artifact in Actions |
| `git tag v1.2.36 && git push origin v1.2.36` on `main` | Deploy CF → Build AAB → **artifact in Actions (download & upload manually)** |
| GitHub UI: Actions → `stable_fallback` → Run workflow | Build AAB from stable branch → artifact only |

## Release command (when ready)

```bash
git checkout main
git merge working
git tag v1.2.36
git push origin main --tags
```

Then download the AAB from Actions → upload to Play Console manually.

That's it — CI/CD handles the rest.
