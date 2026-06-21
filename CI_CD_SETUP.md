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

## Step 3: Get Play Service Account JSON

Google restructured the API Access page. Follow these steps:

**A. Create service account in Google Cloud Console:**

1. Go to https://console.cloud.google.com/apis/credentials (use `qa-genie-ai` project)
2. **Enable the Google Play Developer API**:
   - Go to https://console.cloud.google.com/apis/library/androidpublisher.googleapis.com
   - Make sure `qa-genie-ai` project is selected → click **Enable**
3. Go to **IAM & Admin → Service Accounts** (or use: https://console.cloud.google.com/iam-admin/serviceaccounts)
4. Click **+ Create Service Account**
   - Name: `github-actions`
   - Click **Create and Continue**
   - Role: **Service Accounts → Service Account User**
   - Click **Done**

**B. Create JSON key:**

1. In the Service Accounts list, click the email you just created
2. Go to **Keys** tab
3. Click **Add Key → Create new key** → **JSON** → **Create**
4. File downloads automatically — keep it safe

**C. Link to Google Play Console:**

1. Go to https://play.google.com/console
2. Click **Users & Permissions** (left menu)
3. Click **Invite new users**
4. Paste the service account email (ends with `@qa-genie-ai.iam.gserviceaccount.com`)
5. Under **App permissions**, select your app and grant:
   - ✅ View app information (read-only)
   - ✅ Manage production releases
   - ✅ Manage testing track releases
6. Click **Invite user**

## Step 4: Add secrets to GitHub

Go to: **GitHub → QA_Genie → Settings → Secrets and variables → Actions → Repository secrets** (not environment secrets)

Add these **6 repository secrets**:

| Secret name | Value |
|---|---|
| `KEYSTORE_FILE_B64` | Paste from Step 1 (base64 of qa-genie-release.jks) |
| `KEYSTORE_STORE_PASSWORD` | `Chenchu@QA@Lakshmi@G@` |
| `KEYSTORE_KEY_ALIAS` | `my-key-alias` |
| `KEYSTORE_KEY_PASSWORD` | `Chenchu@QA@Lakshmi@G@` |
| `PLAY_SERVICE_ACCOUNT_JSON` | Paste the full JSON content from Step 3B |
| `FIREBASE_TOKEN` | Paste the new token from Step 2 |

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
