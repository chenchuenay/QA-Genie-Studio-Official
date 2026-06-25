# QA Genie — AI Agent Reference

## Immutable Identifiers
- `PACKAGE_NAME`: `com.enaykumar.qagenie` | `APPLICATIONID`: `com.enaykumar.qagenie`
- **Prod:** `FIREBASE_ID`: `qa-genie-ai` | Storage: `qa-genie-ai.firebasestorage.app`
- **Prod GCS bucket (test cases):** `qa-genie-ai-test-cases` — SA: `qa-genie-ai@appspot.gserviceaccount.com` (objectAdmin)
- **Dev:** `FIREBASE_ID`: `qa-genie-ai-dev` | Storage: `qa-genie-ai-dev.firebasestorage.app`
- **Dev GCS bucket (test cases):** `qa-genie-ai-dev-test-cases` — SA: `qa-genie-ai-dev@appspot.gserviceaccount.com` (objectAdmin)
- **AI Provider:** DeepSeek (`deepseek-v4-flash`, API key in `DEEPSEEK_API_KEY` secret, 45s timeout, temp 0.15)

## Run Commands
- `run prod` = `flutter run --flavor prod -t lib/main.dart --dart-define=MODE=prod`
- `run dev` = `flutter run --flavor dev -t lib/dev_main.dart --dart-define=MODE=dev`
- Build APK dev release = `flutter build apk --flavor dev -t lib/dev_main.dart --dart-define=MODE=dev --release`
- Build AAB prod release = `flutter build appbundle --flavor prod -t lib/main.dart --dart-define=MODE=prod --release`
- Deploy functions prod = `cd functions && npm run deploy:prod`
- Deploy functions dev = `cd functions && npm run deploy:dev`

## Account Types
- **Only two types:** `USER` (Google-authenticated) and `GUEST` (anonymous, device-based).
- **Guest subtypes:**
  - *First-time Guest* → 6 quotas/day (no prior `deviceGuestMapping` on this device)
  - *Returning Guest* → 1 quota/day (prior mapping exists, or from logout/delete)
- Guest creation only happens on **explicit "Continue as Guest" tap**. After logout/delete/clear data, device stays mapped as returning guest via `deviceGuestMapping` (ANDROID_ID keyed, survives data clear).
- Guest → USER upgrade: `linkGoogleAccount` cloud function **preserves** `deviceGuestMapping` — device NEVER gets first-time guest again.

## Tiers
- **Only `CORE` and `PRO` exist.** `CORE` is default for ALL users AND guests.
- `PRO` is **not released** in initial build but implementation must be ready (1-2 tweaks to launch). Pricing proposal: $6.99.
- Returning guests also have `CORE` but with 1 quota (only difference from first-time guest).

## Architecture
```
┌──────────────────────────────────────────────────────────┐
│  Flutter App (Dart)                                      │
│  ┌─────────┐ ┌──────────┐ ┌────────┐ ┌───────────────┐  │
│  │Generation│ │  Suite   │ │  Auth  │ │ Monetization  │  │
│  │  Engine  │ │  Mgmt   │ │Service │ │ (Ads/Quotas)  │  │
│  └────┬─────┘ └────┬─────┘ └───┬────┘ └───────┬───────┘  │
│       │            │           │              │          │
│  ┌────▼────────────▼───────────▼──────────────▼───────┐  │
│  │          FunctionsService (18+ cloud fn calls)      │  │
│  └─────────────────────┬──────────────────────────────┘  │
├────────────────────────┼─────────────────────────────────┤
│  Firebase Cloud Functions (Node 22)                      │
│  ┌─────────────────────┼──────────────────────────────┐  │
│  │  26 functions in functions/index.js                 │  │
│  │  Key groups: Auth(3), Generation(2), Quota(5),     │  │
│  │  Suite sync(3), Account(3), Analytics(5), Misc(5)  │  │
│  └──────┬──────────────┼──────────────┬───────────────┘  │
│         │              │              │                  │
│  ┌──────▼────┐ ┌───────▼───────┐ ┌────▼─────────────┐  │
│  │ Firestore │ │ GCS Bucket    │ │ DeepSeek API      │  │
│  │ (metadata,│ │ (test cases)  │ │ (AI generation)   │  │
│  │ quotas,   │ │ gzipped JSON  │ │                   │  │
│  │ profiles) │ │               │ │                   │  │
│  └───────────┘ └───────────────┘ └──────────────────┘  │
└──────────────────────────────────────────────────────────┘
```

## Firestore Collections

### Client-accessible (via security rules):
| Collection | Access |
|---|---|
| `memberProfiles/{email}` | Read by `uid` field or email doc ID. No write. |
| `memberData/{tier}/{uid}/{document=**}` | Read by `uid` in path. No write. |
| `issue_reports/{reportId}` | Create (any auth). Read/update/delete by owner uid. |
| `users/{uid}`, `usage/{uid}`, `userSuites/{uid}`, `userSessions/{uid}` | Owner read/write. |
| `analytics/{document}` | Auth read. No write. |

### Cloud-function-only (deny-all client rules):
`guests`, `deviceUsage`, `deviceGuestMapping`, `emailCooldown`, `the_qag_registry`, `processed_requests`

### Suite storage split:
- **Firestore metadata:** `memberData/{tier}/{uid}/{date}/suites/{serial}` → `{moduleName, feature, createdAt, updatedAt, uid, date}`
- **GCS test cases:** `memberData/{tier}/{uid}/{date}/suites/{serial}.json` (gzipped, auto-decompressed on download)
- **Counter:** `memberData/{tier}/{uid}/_counter_suites` → atomic serial number

### Session doc:
`memberData/{tier}/{profileUid}/_session` → `{deviceId, lastActive}`

---

## Immutable Rules (Pre-Planning & Fix-Applying)

### 1. Seamless Navigation
All screen transitions must be lag-free. **No loading indicators or loading screens** are ever shown.

### 2. Guest Restrictions
- Guests cannot see **Delete Account** or **Logout**.
- Guests cannot submit feedback. Show "Sign in with Google to share your feedback" in feedback dialog. No redirect to ReportIssueScreen.
- Only **stars** are collected from export success dialog of first-time guest (6-quota guest).
- User Logout → auto move to **new returning guest** (1 quota). Returning guest is a temporary account — **no merge** when linking Google. On Google link, delete returning guest.

### 3. AI Test Case Generation & Fallback
- Aim to **always deliver AI-generated test cases**. AI must not fail to produce good test cases.
- **If API call already sent** and we receive nothing → use fallback generator. **No retries** in this case.
- **If API call not sent yet** → we can retry AI.
- **Partial Fallback Repair:** If AI returns some good cases and some bad, fallback generator must **only repair the bad ones** (using same fallback domains). Do not regenerate all test cases.
- Fallback generator must produce test cases that appear **at least 70% similar** to AI-generated cases.

### 4. Ad Preloading
Exactly **one ad must always be preloaded** so ads appear instantly when needed.

### 5. Online / Offline Behaviour (Production Mode)
- **Online required for:** generating test cases, exporting test cases, exporting a summary. Show "No Internet" screen if offline.
- **Offline allowed for:** editing test cases, checking system assistant, checking/editing test suites and saving them.
- **Never allow offline generations or exports.**

### 6. Account Deletion & Cool-down
- Delete or Logout → auto move to **new returning-guest account** (1 quota).
- Same Google account cannot be used again for **24 hours** (global cool-down, not device-based). Enforced via `emailCooldown/{email}` doc.
- Different email on same device works immediately.
- **No data merge** on guest → member move. Quota and data not reflected from old account.
- **Web deletion page:** `qagenies.com/delete-account.html` — email `wipe@qagenies.com` from registered email. Must include account details. Deletion within 24-48h. **No take backs.**
- **Google Play requirement:** Both in-app + web deletion URL must exist.

### 7. Error Display
- **No snackbars in production.** All user-facing messages must be in **dialog boxes.**
- Messages must be human-readable, never raw errors.
- All dialogs must have background blur — sigma **15**, unified single source via `showBlurredDialog` only (no redundant internal BackdropFilters).

### 8. Quota Visibility
- Quota may be shown **only** in the "Generate hint" area. Nowhere else.
- Quota-exhausted popup must show **exact time remaining** until reset.

### 9. Ad-Rewarded Quotas
- Ad-rewarded quotas apply **only to `CORE` users.**
- `CORE` is default for users and guests; returning guests differ only in 1 quota vs 6.

### 10. Data Collection & Sync
- **Collect metadata:** email, device ID, etc.
- **Never** collect test cases, modules, or test case content.
- Exception: collect full issue reports.
- **Live sync is never performed on test cases.**
- Only one field is synced: `status` (from `issue_reports`). Linked to Firebase, shown to users. Sync frequency: **once every 7 days** (Monday).

### 11. Pro Version Strategy
- `PRO` tier is **not released** in initial build.
- `PRO` implementation must be **ready** (one or two modifications to launch). Pricing $6.99.

### 12. Cost & Performance Optimization
- Always minimise reads, writes, and checks while delivering full features and security.
- Server cache TTL: 10s (in-memory, uid-scoped for dashboard).
- Client dashboard cache TTL: 10s.
- Batching allowed, but security takes higher priority.

### 13. Auth Dialog
- **Not dismissible** by back button — user must tap Continue with Google or Continue as Guest.
- `PopScope(canPop: false)` on widget level, plus `barrierDismissible: false`.
- After multi-device conflict [No] → auth dialog restricted to Google-only (guest hidden, back blocked) via `_forceGoogleOnly` state.
- Button uses `Stack` with both idle/loading rows always rendered (same icon + text + 24px dots spacer, zero layout shift). Only dots animate inside fixed `SizedBox(width: 24)`.

### 14. Multi-Device Session System
1. **`checkSessionByEmail`** cloud function — checks session conflict **before** Google sign-in linking. No auth required. Rate-limited 10/min by email.
2. **Conflict dialog** BEFORE `linkWithCredential` (no partial Firebase auth state). [No] → sign out Google, restrict to Google-only. [Okay] → proceed, old device gets kicked.
3. **`registerSession`** cloud function — registers device after sign-in. Rate-limited 20/min.
4. **`SessionMonitor`** (client) — realtime Firestore snapshot on `_session` doc. On `deviceId` change → "Signed in on another device" dialog → `hardSignOut()` → local data wiped → auth dialog.
5. `hardSignOut()`: wipes local DB via `DatabaseService.clearAll()` + `invalidateSuitesCache()`, signs out Google + Firebase, clears prefs (preserves `first_launch_completed`, `never_show_guidelines`, `first_launch_guidelines_shown`). **No guest re-creation.**

### 15. Local Database (SQLite)
- **Identity = `DeviceUtils.getUniqueId()`** (ANDROID_ID) for ALL users — guests and members share same DB file.
- After `clearAll()` + re-init, same file is reused (contents empty).
- **Key tables:** `suites` (id, moduleName, feature, platform, created_at, cloud_id, dirty), `test_cases` (id, suite_id FK, case_json), `reported_issues`, `pending_deletes`.
- `dirty` flag prevents overwriting local edits with stale cloud data.
- `clearAll()` deletes all rows + resets sequences. Does NOT close DB or delete file.
- On logout/kick: DB is cleared. Guest afterwards sees empty suites.

### 16. Quota System (Server-Authoritative)
| Type | Free Generations/Day | Rewarded Generations/Day | Cases/Batch | Exports/Day |
|---|---|---|---|---|
| CORE (user) | 0 | 6 | 10 | 50 |
| PRO (user) | 15 | 0 | 20 | unlimited |
| First-time Guest | 0 | 6 | 10 | 50 |
| Returning Guest | 0 | 1 | 10 | 50 |

- Quota constants in **two places** (must keep in sync):
  - `lib/app/config/app_config.dart` (client)
  - `functions/index.js` (server, lines 13-23)
- Guest quotas tracked by `deviceUsage/{deviceId}` (survives account deletion).
- Member quotas tracked by `usage/{uid}`.
- Ad reward tokens stored in `usage/{uid}/usedRewards/{token}`.

### 17. Policies & Legal (In-App = Website)
All 4 policies must be **identical** in-app (`legal_documents.dart`) and on website (`qagenies.com/*.html`):

| Document | URL | Contact |
|---|---|---|
| Privacy Policy | `qagenies.com/privacy.html` | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| Terms of Service | `qagenies.com/terms.html` | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| AI Disclaimer | `qagenies.com/ai-disclaimer.html` | *(no contact)* |
| Ads & Monetization | `qagenies.com/ads-monetization.html` | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| Delete Account | `qagenies.com/delete-account.html` | wipe@qagenies.com (no take backs) |

- **Account deletion email:** `wipe@qagenies.com` — must be sent from registered email, include account details, 24-48h processing, **irreversible**.
- Contact email in About screen: `chenchuenay@qagenies.com`
- Website contact/footer: `hello@qagenies.com`

### 18. AI In-App Reporting (Google Play Requirement)
- Report/flag button must be accessible from the **generation result screen** (`SuitePreviewScreen`). Currently: flag icon in app bar opens `ReportIssueScreen`.
- `ReportIssueScreen` supports: issue type dropdown, title, description, steps, device info toggle.
- Guests see lock screen → "Sign in with Google to share your feedback".

### 19. UI Conventions
- **Dark theme only.** Colors defined in `app_colors.dart`.
- **Blur:** Always sigma 15, single source via `showBlurredDialog` in `dialog_utils.dart`.
- **All user-facing messages** in dialogs, never snackbars.
- **Tour (walkthrough):** `BackdropFilter` outside `FadeTransition` (blur persistent across steps). 6-step overlay.
- `SuitePreviewScreen`: SafeArea removed from Export button, reduced padding.

### 20. Ad Configuration
- **Currently active:** Google test ad unit IDs (`ca-app-pub-3940256099942544/...`).
- **Real IDs (swap at Play Store launch):** Publisher `ca-app-pub-5950082050771694` — 3 rewarded, 1 interstitial, 1 native. Commented in `ad_units.dart`.
- **Formats:** Rewarded video only (user-initiated). No interstitials, banners, or native in prod.
- **Mediation partner:** Unity Ads (disclosed in policies).

### 21. Cloud Functions Quick Reference
| Function | Auth | Rate Limit | Key Collections |
|---|---|---|---|
| `checkSessionByEmail` | No | 10/min/email | `memberProfiles` |
| `registerSession` | Yes | 20/min/uid | `memberData/{tier}/{uid}/_session` |
| `generate` | Yes | 10/min/uid | `usage`, `processed_requests`, DeepSeek AI |
| `getOrCreateGuestToken` | No | 5/min/deviceId | `deviceGuestMapping`, `guests`, `usage` |
| `linkGoogleAccount` | Yes | 3/min/uid | `memberProfiles`, `guests`, `usage` |
| `deleteAccount` | Yes | 2/min/uid | `emailCooldown`, GCS, `memberData` |
| `pushMemberSuite` | Yes | 30/min/uid | GCS write, `memberData` |
| `getMemberSuites` | Yes | 10/min/uid | GCS read, `memberData` |
| `deleteMemberSuite` | Yes | none | GCS delete, `memberData` |
| `checkGenerationQuota` | Yes | none (cached 10s) | `usage`, `guests` |
| `getMemberDashboard` | Yes | none (cached 10s) | `usage`, `memberProfiles` |

### 22. Key Files Map
| File | Purpose |
|---|---|
| `lib/features/legal/data/legal_documents.dart` | All 4 policy documents + URLs |
| `lib/features/auth/services/auth_service.dart` | signOut, hardSignOut, linkWithGoogle |
| `lib/features/auth/services/session_monitor.dart` | Realtime multi-device conflict detection |
| `lib/features/auth/ui/auth_dialog.dart` | Auth dialog with conflict check, forceGoogleOnly |
| `lib/features/splash/splash_screen.dart` | Entry point, cold start session check |
| `lib/shared/navigation/main_screen.dart` | Main scaffold, bottom nav, SessionMonitor init |
| `lib/core/database/database_service.dart` | SQLite DB: initDatabase(identity), clearAll, migrations |
| `lib/core/cloud/cloud_sync_service.dart` | Push/pull suites to/from cloud |
| `lib/features/monetization/ads/ad_manager.dart` | Ad preloading + showing rewarded ads |
| `lib/features/monetization/ads/ad_units.dart` | Test (active) + real (commented) ad unit IDs |
| `lib/features/monetization/logic/usage_manager.dart` | Quota checks, tier resolution, dashboard caching |
| `lib/app/config/app_config.dart` | Client-side quota constants, feature flags |
| `lib/firebase/cloud_functions/functions_service.dart` | All 18+ cloud function Dart bindings |
| `lib/shared/dialogs/export_success_dialog.dart` | Star rating + feedback trigger |
| `lib/shared/dialogs/feedback_dialog.dart` | Guest-locked feedback prompt |
| `lib/features/support/ui/report_issue_screen.dart` | Issue report form (full) |
| `lib/core/utils/dialog_utils.dart` | `showBlurredDialog` (sigma 15, single blur source) |
| `lib/features/suites/ui/screens/suite_preview_screen.dart` | Generation result view, Report flag icon |
| `lib/engine/orchestration/pipeline_orchestrator.dart` | AI → Parse → Repair → Validate → Fallback → Finalize |
| `lib/engine/orchestrator/deterministic_engine.dart` | Local fallback generator (no AI) |
| `website/*.html` | All policy pages + delete-account.html |
| `functions/index.js` | All 25 cloud functions |
| `firestore.rules` | Security rules for all collections |
| `firestore.indexes.json` | Composite indexes |

### 23. Contact Canonical Emails
- **General enquiries:** `hello@qagenies.com`
- **Creator:** `chenchuenay@qagenies.com`
- **Account deletion:** `wipe@qagenies.com` (no take backs)
- **Website footer contact:** `hello@qagenies.com`
