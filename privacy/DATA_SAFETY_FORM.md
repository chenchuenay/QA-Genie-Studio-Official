# Google Play Data Safety Form — QA Genie

This document maps every data type required by the Google Play Data Safety section to QA Genie's actual data practices, verified against source code.

---

## 1. Location

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Approximate location | **No** | — | Not collected, no permission declared |
| Precise location | **No** | — | Not collected, no permission declared |

---

## 2. Personal Info

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Name | **Yes** (Google users only) | **No** | Display name from Google Sign-In; stored in Firestore `users/{uid}` |
| Email address | **Yes** (Google users only) | **No** | Email from Google Sign-In; stored in Firestore `users/{uid}` |
| User IDs | **Yes** | **No** | Firebase UID (all users); Device ID (guests); stored in Firestore `guests/{uid}`, `deviceGuestMapping/{deviceId}`, `the_qag_registry/{uid}` |
| Address | **No** | — | Not collected |
| Phone number | **No** | — | Not collected |
| Race/ethnicity | **No** | — | Not collected |
| Political/religious beliefs | **No** | — | Not collected |
| Sexual orientation | **No** | — | Not collected |
| Other personal info | **No** | — | Not collected |

---

## 3. Financial Info

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Payment info | **No** | — | No payment processing; "Pro" tier is managed internally (no financial collection) |
| Purchase history | **No** | — | Not applicable |
| Credit score | **No** | — | Not collected |
| Other financial info | **No** | — | Not collected |

---

## 4. Health & Fitness

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Health info | **No** | — | Not collected |
| Fitness info | **No** | — | Not collected |

---

## 5. Messages

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Emails | **No** | — | Not collected |
| SMS/MMS | **No** | — | Not collected |
| Other in-app messages | **No** | — | Not collected |

---

## 6. Photos & Videos

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Photos | **No** | — | Not collected, no camera/storage permission |
| Videos | **No** | — | Not collected |
| Other media | **No** | — | Not collected |

---

## 7. Audio Files

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Voice/sound recordings | **No** | — | Not collected |
| Music files | **No** | — | Not collected |
| Other audio | **No** | — | Not collected |

---

## 8. Files & Docs

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Files & docs | **No** | — | Generated test cases are exported locally via share sheet (user-initiated); no files are uploaded to our servers |
| Notes | **Yes** (user-provided) | **Via AI provider** | Prompt notes/constraints entered by user during test generation are sent to DeepSeek API (sanitized) |

---

## 9. Calendar

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Calendar events | **No** | — | Not collected |

---

## 10. Contacts

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Contacts | **No** | — | Not collected |

---

## 11. App Activity

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| App interactions | **Yes** | **No** | Firebase Analytics: app opens, screen views, generation/export events; stored in aggregated analytics |
| In-app search history | **No** | — | Not collected |
| Installed apps | **No** | — | Not collected |
| User-generated content | **Yes** | **Via AI provider** | Test generation prompts sent to DeepSeek (sanitized); issue report descriptions stored in Firestore |
| Other actions | **Yes** | **No** | Generation counts, export counts, pro interest events — stored for quota enforcement |

**Analytics events collected** (Firebase Analytics):
- `app_open`
- `generation_started` (platform, mode, requested_count)
- `generation_completed` (platform, mode, generated_count, duration_ms)
- `generation_failed` (platform, mode, reason)
- `export_completed` (format, case_count)
- `rewarded_ad_completed` (placement)
- `upgrade_intent` (source)
- `bug_report_submitted` (category)
- Screen views

---

## 12. Web Browsing

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Web browsing history | **No** | — | Not collected; network check contacts `clients3.google.com/generate_204` (no data sent) |

---

## 13. App Info & Performance

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Crash logs | **No** | — | Firebase Crashlytics is **not** implemented; errors logged locally via `debugPrint` only |
| Diagnostics | **Yes** | **No** | Device model, app version, platform (included in issue reports when user toggles ON) |
| Other app performance | **No** | — | Not collected |

---

## 14. Device & Other IDs

| Subtype | Collected? | Shared? | Details |
|---------|-----------|---------|---------|
| Device ID | **Yes** | **No** | Firebase Installation ID stored in SharedPreferences as `unique_device_identifier`; used for guest auth, quota enforcement, generation requests, account deletion |
| Advertising ID | **No** (directly) | **Via AdMob SDK** | We do not directly access the advertising ID; however, Google AdMob SDK may automatically collect it for ad serving/personalization |

---

## Data Sharing Summary

| Third Party | Data Types Shared | Purpose | User Control |
|-------------|------------------|---------|-------------|
| **DeepSeek** (AI) | Sanitized prompt text, generation context (module/feature/platform) | AI test case generation | No opt-out for generation (but prompts are sanitized) |
| **Google Firebase** (Auth, Firestore, Functions, Analytics) | UID, email, device ID, usage metrics, issue reports | Auth, database, compute, analytics | Account deletion available |
| **Google AdMob** | Advertising ID, device info, IP address (handled by SDK) | Rewarded advertising | Opt-in (user must choose to watch ad); ad personalization can be disabled in device settings |
| **Google Gemini** (dev only) | Full prompt text, API key | Fallback AI generation | Not used in production builds |

## Data Encryption

- **In transit**: All network communications use HTTPS/TLS
- **At rest**: Firestore data encrypted at rest (Google Cloud default)
- **Local device**: SQLite database; no separate encryption (device-level encryption applies)

## Data Deletion

- **In-app account deletion**: Account → Delete Account → removes Firestore docs, deletes Firebase Auth user
- **Local data**: Must clear app data or uninstall; we cannot remotely wipe local storage
- **Issue reports**: Anonymized on deletion (UID/display name replaced with "deleted_user")
- **Cooldown**: Device guest mapping retains a deletion timestamp for cooldown period to prevent quota abuse
