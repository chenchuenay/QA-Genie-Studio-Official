# QA Genie — AI Agent Reference

## Immutable Identifiers

- `PACKAGE_NAME`: `com.enaykumar.qagenie` | `APPLICATIONID`: `com.enaykumar.qagenie`
- **Prod:** `FIREBASE_ID`: `qa-genie-ai` | Storage: `qa-genie-ai.firebasestorage.app`
- **Prod GCS bucket (test cases):** `qa-genie-ai-test-cases` — SA: `qa-genie-ai@appspot.gserviceaccount.com` (objectAdmin)
- **Dev:** `FIREBASE_ID`: `qa-genie-ai-dev` | Storage: `qa-genie-ai-dev.firebasestorage.app`
- **Dev GCS bucket (test cases):** `qa-genie-ai-dev-test-cases` — SA: `qa-genie-ai-dev@appspot.gserviceaccount.com` (objectAdmin)
- **AI Provider:** DeepSeek (`deepseek-v4-flash`, API key in `DEEPSEEK_API_KEY` secret, 45s timeout, temp 0.15)

## Build Rule

- **Never build with `--dart-define=IS_DEV=true` unless explicitly asked.** Only build the production APK/AAB unless the user says "dev".

## Run Commands

- `run dev` = `flutter run --dart-define=IS_DEV=true`
- `run prod` = `flutter run`
- Build APK dev = `flutter build apk --release --dart-define=IS_DEV=true --obfuscate --split-debug-info=build/debug-info`
- Build AAB prod = `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info`
- Deploy functions prod = `cd functions && npm run deploy:prod`
- Deploy functions dev = `cd functions && npm run deploy:dev`

## Account Types

- **Only two types:** `USER` (Google-authenticated) and `GUEST` (anonymous, device-based).
- **Guest subtypes:**
  - _First-time Guest_ → 6 quotas/day (no prior `deviceGuestMapping` on this device)
  - _Returning Guest_ → 1 quota/day (prior mapping exists, or from logout/delete)
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
│  │  Two files: index.prod.js / index.dev.js              │  │
│  │  Selected at deploy via `cp *.js index.js`           │  │
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

| Collection                                                             | Access                                              |
| ---------------------------------------------------------------------- | --------------------------------------------------- |
| `memberProfiles/{email}`                                               | Read by `uid` field or email doc ID. No write.      |
| `memberData/{tier}/{uid}/{document=**}`                                | Read by `uid` in path. No write.                    |
| `issue_reports/{reportId}`                                             | Create (any auth). Read/update/delete by owner uid. |
| `users/{uid}`, `usage/{uid}`, `userSuites/{uid}`, `userSessions/{uid}` | Owner read/write.                                   |
| `analytics/{document}`                                                 | Auth read. No write.                                |

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

| Type             | Free Generations/Day | Rewarded Generations/Day | Cases/Batch | Exports/Day |
| ---------------- | -------------------- | ------------------------ | ----------- | ----------- |
| CORE (user)      | 0                    | 6                        | 10          | 50          |
| PRO (user)       | 15                   | 0                        | 20          | unlimited   |
| First-time Guest | 0                    | 6                        | 10          | 50          |
| Returning Guest  | 0                    | 1                        | 10          | 50          |

- Quota constants in **two places** (must keep in sync):
  - `lib/app/config/app_config.dart` (client)
  - `functions/index.prod.js` / `index.dev.js` (server, lines 13-23)
- Guest quotas tracked by `deviceUsage/{deviceId}` (survives account deletion).
- Member quotas tracked by `usage/{uid}`.
- Ad reward tokens stored in `usage/{uid}/usedRewards/{token}`.

### 17. Policies & Legal (In-App = Website)

All 4 policies must be **identical** in-app (`legal_documents.dart`) and on website (`qagenies.com/*.html`):

| Document           | URL                                  | Contact                                                         |
| ------------------ | ------------------------------------ | --------------------------------------------------------------- |
| Privacy Policy     | `qagenies.com/privacy.html`          | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| Terms of Service   | `qagenies.com/terms.html`            | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| AI Disclaimer      | `qagenies.com/ai-disclaimer.html`    | _(no contact)_                                                  |
| Ads & Monetization | `qagenies.com/ads-monetization.html` | General: hello@qagenies.com / Creator: chenchuenay@qagenies.com |
| Delete Account     | `qagenies.com/delete-account.html`   | wipe@qagenies.com (no take backs)                               |

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

| Function                | Auth | Rate Limit        | Key Collections                            |
| ----------------------- | ---- | ----------------- | ------------------------------------------ |
| `checkSessionByEmail`   | No   | 10/min/email      | `memberProfiles`                           |
| `registerSession`       | Yes  | 20/min/uid        | `memberData/{tier}/{uid}/_session`         |
| `generate`              | Yes  | 10/min/uid        | `usage`, `processed_requests`, DeepSeek AI |
| `getOrCreateGuestToken` | No   | 5/min/deviceId    | `deviceGuestMapping`, `guests`, `usage`    |
| `linkGoogleAccount`     | Yes  | 3/min/uid         | `memberProfiles`, `guests`, `usage`        |
| `deleteAccount`         | Yes  | 2/min/uid         | `emailCooldown`, GCS, `memberData`         |
| `pushMemberSuite`       | Yes  | 30/min/uid        | GCS write, `memberData`                    |
| `getMemberSuites`       | Yes  | 10/min/uid        | GCS read, `memberData`                     |
| `deleteMemberSuite`     | Yes  | none              | GCS delete, `memberData`                   |
| `checkGenerationQuota`  | Yes  | none (cached 10s) | `usage`, `guests`                          |
| `getMemberDashboard`    | Yes  | none (cached 10s) | `usage`, `memberProfiles`                  |

### 22. Key Files Map

| File                                                       | Purpose                                                 |
| ---------------------------------------------------------- | ------------------------------------------------------- |
| `lib/features/legal/data/legal_documents.dart`             | All 4 policy documents + URLs                           |
| `lib/features/auth/services/auth_service.dart`             | signOut, hardSignOut, linkWithGoogle                    |
| `lib/features/auth/services/session_monitor.dart`          | Realtime multi-device conflict detection                |
| `lib/features/auth/ui/auth_dialog.dart`                    | Auth dialog with conflict check, forceGoogleOnly        |
| `lib/features/splash/splash_screen.dart`                   | Entry point, cold start session check                   |
| `lib/shared/navigation/main_screen.dart`                   | Main scaffold, bottom nav, SessionMonitor init          |
| `lib/core/database/database_service.dart`                  | SQLite DB: initDatabase(identity), clearAll, migrations |
| `lib/core/cloud/cloud_sync_service.dart`                   | Push/pull suites to/from cloud                          |
| `lib/features/monetization/ads/ad_manager.dart`            | Ad preloading + showing rewarded ads                    |
| `lib/features/monetization/ads/ad_units.dart`              | Test (active) + real (commented) ad unit IDs            |
| `lib/features/monetization/logic/usage_manager.dart`       | Quota checks, tier resolution, dashboard caching        |
| `lib/app_config.dart`                                      | IS_DEV compile-time switch (--dart-define)             |
| `lib/firebase/cloud_functions/functions_service.dart`      | All 18+ cloud function Dart bindings                    |
| `lib/shared/dialogs/export_success_dialog.dart`            | Star rating + feedback trigger                          |
| `lib/shared/dialogs/feedback_dialog.dart`                  | Guest-locked feedback prompt                            |
| `lib/features/support/ui/report_issue_screen.dart`         | Issue report form (full)                                |
| `lib/core/utils/dialog_utils.dart`                         | `showBlurredDialog` (sigma 15, single blur source)      |
| `lib/features/suites/ui/screens/suite_preview_screen.dart` | Generation result view, Report flag icon                |
| `lib/engine/orchestration/pipeline_orchestrator.dart`      | AI → Parse → Repair → Validate → Fallback → Finalize    |
| `lib/engine/orchestrator/deterministic_engine.dart`        | Local fallback generator (no AI)                        |
| `website/*.html`                                           | All policy pages + delete-account.html                  |
| `functions/index.js`                                       | Generated — copied from *.prod.js or *.dev.js at deploy |
| `functions/index.prod.js`                                  | Production cloud functions (deployed to qa-genie-ai)    |
| `functions/index.dev.js`                                   | Dev cloud functions (deployed to qa-genie-ai-dev)       |
| `firestore.rules`                                          | Security rules for all collections                      |
| `firestore.indexes.json`                                   | Composite indexes                                       |

### 23. Contact Canonical Emails

- **General enquiries:** `hello@qagenies.com`
- **Creator:** `chenchuenay@qagenies.com`
- **Account deletion:** `wipe@qagenies.com` (no take backs)
- **Website footer contact:** `hello@qagenies.com`

note:always -rm,clean,pug get before building any apk or flutter runs
also try to uninstall apps before installing

## Git Discipline

- **Never checkout, reset, merge, or switch branches while uncommitted changes exist.** Always `git commit` or `git stash` first. Failing to do so WILL lose uncommitted work.

## Anchored Summary — Ontology2 + Quota Edge Cases

### Goal
Replace hardcoded domain templates with a generative ontology engine that produces AI-quality test cases for all 10 domains using entity property definitions.

### Key Decisions
- **PropertyDef is the core abstraction** — every generator reads property types/examples/constraints rather than switching on domain name.
- **VariationPool uses seeded Random** for deterministic but varied output.
- **OntologyScenarioPlanner** iterates entity+action pairs with round-robin category cycling — simpler than old Relationship-graph expansion planner.
- **Quota consumed AFTER DeepSeek call** (cost incurred first), but with overdraft safety for race conditions — DeepSeek cost always honoured with fallback.
- **Nonce expiry checked BEFORE DeepSeek call** to avoid wasting AI cost on expired tokens.
- **`callDeepSeek` always returns** (never throws), so every return from it is treated as "AI was attempted" for quota purposes, except `HTTP_4xx` / `CLIENT_ERROR` which are classified as no-cost.

### Quota Edge Cases (SCENARIO 2.2, 2.3, 4.5)
- **SCENARIO 2.2 (Race → Overdraft):** When DeepSeek was called + ad was watched + quota is exhausted by another request in the same window, the transaction allows one over-limit increment (`!aiFailed` guard on LIMIT_REACHED throw) and returns fallback. Quota is consumed because DeepSeek cost was incurred.
- **SCENARIO 2.3 (No-cost AI error → free fallback):** `HTTP_4xx` / `CLIENT_ERROR` errors from DeepSeek are classified as `aiNoCost = true`. If ad was watched, the transaction skips counter increment entirely and returns `freeFallback: true`. No quota consumed. Pre-DeepSeek errors (transport, auth) are handled by the existing catch block — they never enter transaction, no quota consumed.
- **SCENARIO 4.5 (Expired nonce → skip DeepSeek, free fallback):** Before `callDeepSeek`, the nonce timestamp is checked against `processed_requests`. If expired (>5 min), a single-document transaction atomically consumes the nonce and returns `freeFallback: true` without ever calling DeepSeek. No AI cost, no quota consumed.

### Critical Context
- Version: 1.2.67 (versionCode 23)
- DeepSeek cloud function: `timeoutSeconds: 60`, fetch abort at 55s, model `deepseek-v4-flash`, `extra_body: { thinking: { type: "disabled" } }`, `response_format: { type: "json_object" }`.
- `DEEPSEEK_API_KEY` must be set as Firebase secret — missing it causes `HTTP_401` on every API call.
- `IdGenerator.generate()` is truly dead code after Renumber removal. `_reId()` replaces it in copy/move.
- Copy/move queries `getTestCasesForSuite(targetSuiteId)` and uses `_reId(originalId, existing.length + position + 1)` — preserves prefix, only number changes.
- `maxLength` on TextField: does NOT truncate `controller.text =` (AI content passes unhindered); stops user typing/paste at limit. Counter via `counterStyle` only (no `buildCounter` in Flutter 3.44.1).
- `Flutter 3.44.1` — no `buildCounter` or `counter` widget in `InputDecoration`. Only `counterText` + `counterStyle` available.
- All builds: `flutter clean && flutter pub get && flutter build apk --release --obfuscate --split-debug-info=build/debug-info`. Must uninstall before install on device.
- Current fallback: 300+ hardcoded branches across 6 generators, cannot handle domains not explicitly coded. New approach: single set of generators reads PropertyDef list + ActionDef transitions — works for any domain.
- 10 domains confirmed working: Identity → Login/SSO, Commerce → Checkout, Banking → Transfer, Medical → Patient Records, Scheduling → Book Appointment, Integration → Webhook, AI/ML → Model Training, Social → Create Post, Tech → Server Deploy, Robotics → Robot Mission.
- All 717 engine tests pass (0 failures), 0 analyzer warnings across entire project.

### Relevant Files
- `lib/engine/ontology2/model/`: entity_def, action_def, state_def, domain_ontology, step_template — core data model
- `lib/engine/ontology2/registry/domain_index.dart`: master registry with detect() for all 10 domains
- `lib/engine/ontology2/registry/domains/`: 10 domain data files (identity, commerce, banking, medical, scheduling, integration, ai_ml, social, tech, robotics)
- `lib/engine/ontology2/generators/`: 5 ontology generators (title, data, step, precondition, expected_result)
- `lib/engine/ontology2/planners/ontology_scenario_planner.dart`: native scenario planner for V2 engine
- `lib/engine/orchestrator/deterministic_engine_v2.dart`: V2 orchestrator — drop-in replacement for old engine
- `lib/engine/orchestration/pipeline_orchestrator.dart`: hard error logic updated to skip SERVICE_UNAVAILABLE when ad was watched
- `lib/engine/orchestration/stages/ai_generation_stage.dart`: handles `freeFallback` flag from cloud fn, sets `hasQuotaBeenConsumed` accordingly
- `lib/engine/orchestration/stages/fallback_stage.dart`: uses DeterministicEngineV2
- `lib/engine/models/pipeline_models.dart`: GenerationRequest carries adToken, AiStageResult carries hasQuotaBeenConsumed
- `functions/index.prod.js` + `functions/index.dev.js`: `exports.generate` restructured — pre-DeepSeek nonce expiry check (4.5), no-cost error classification (2.3), overdraft for race condition (2.2)
- `lib/core/network/network_guard.dart`: HTTP cache cleared on connectivity change
- `lib/core/network/network_ui_helper.dart`: `ensureProductionOnline()` calls `hasInternet()`, shows NoInternetScreen dialog
- `lib/firebase/cloud_functions/functions_service.dart`: added `requestAdNonce()` binding
- `lib/features/generation/ui/screens/home_screen.dart`: calls `FunctionsService.requestAdNonce()` before ad dialog
- `lib/features/account/ui/account_screen.dart`: `_loadCached()`, `_cachedDisplayName`, caching in `_loadData()`
- `lib/features/suites/ui/screens/suite_preview_screen.dart`: Renumber removed, `_reId()` added, duplicate guard wiring
- `lib/features/generation/ui/widgets/master_table.dart`: 7 fields with maxLength + counterStyle, duplicate indices
- `lib/shared/dialogs/export_preview_dialog.dart`: maxLength + counterStyle, ListView.separated
- `lib/features/summary/ui/summary_report_screen.dart` + `summary_report_preview_screen.dart`: ListView.builder for performance
- `lib/core/utils/id_generator.dart`: `IdGenerator.generate(module, index)` — dead code after Renumber removal

