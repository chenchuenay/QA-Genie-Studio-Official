# QA Genie — AI Agent Reference

---

## 1. Quick Reference

### Device
adb connect 10.184.222.252:5555

### Identifiers
| Item | Value |
|------|-------|
| PACKAGE_NAME / APPLICATIONID | `com.enaykumar.qagenie` |
| Prod Firebase ID | `qa-genie-ai` |
| Prod Storage | `qa-genie-ai.firebasestorage.app` |
| Prod GCS (test cases) | `qa-genie-ai-test-cases` (SA: `qa-genie-ai@appspot.gserviceaccount.com`) |
| Dev Firebase ID | `qa-genie-ai-dev` |
| Dev Storage | `qa-genie-ai-dev.firebasestorage.app` |
| Dev GCS (test cases) | `qa-genie-ai-dev-test-cases` (SA: `qa-genie-ai-dev@appspot.gserviceaccount.com`) |
| AI Provider | DeepSeek (`deepseek-v4-flash`, API key in `DEEPSEEK_API_KEY` secret, 45s timeout, temp 0.15) |

### Run Commands
| Action | Command |
|--------|---------|
| Run dev | `flutter run --dart-define=IS_DEV=true` |
| Run prod | `flutter run` |
| Build APK dev | `flutter build apk --release --dart-define=IS_DEV=true --obfuscate --split-debug-info=build/debug-info` |
| Build APK prod | `flutter build apk --release --obfuscate --split-debug-info=build/debug-info` |
| Build AAB prod | `flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info` |
| Deploy functions dev | `cd functions && npm run deploy:dev` |
| Deploy functions prod | `cd functions && npm run deploy:prod` |

---

## 2. Current Phase: Pre-Launch

### Prod JS Freeze (20+ days from Jun 30)
- **DO NOT** modify `functions/index.prod.js` for any reason.
- **DO NOT** run `npm run deploy:prod`.
- All dev work goes in `functions/index.dev.js` only.
- Prod changes only after: (a) closed testing completes, (b) app is live, (c) you explicitly approve.

### Production Launch Checklist
#### Before Launch
- [ ] Verify Privacy/ToS/AI/Ads pages on qagenies.com are up to date
- [ ] Remove test accounts from Firebase
- [ ] Set up App Check enforcement
- [ ] Finalize store listing (screenshots, description, category)
- [ ] Test all auth flows one last time with the release build

#### At Launch
- [ ] Swap ad unit IDs (test → real) in `lib/features/monetization/ads/ad_units.dart`
- [ ] Add 2 mediation partners (AppLovin + Mintegral) to AdMob bidding (needs live app link first)

#### 2 Months Post-Launch
- [ ] Launch PRO tier ($6.99) — gating already implemented, needs Play product IDs + flip switch
- [ ] Use feedback to validate pricing before flipping PRO

### Google Review Catch (Fix Later)
**ANR:** `FlutterJNI.nativeSurfaceDestroyed` — main thread blocked during splash→MainScreen transition
- **Likely cause:** `migrateDataToCurrentDb()` blocking in `_backgroundInit()` during surface lifecycle
- **Fix:** Already applied — `Future.delayed(2s)` + skip if DB already migrated
- **Priority:** Low (1 user in 7 days)

---

## 3. Architecture

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
│  │  Selected via `cp *.js index.js` at deploy           │  │
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

### Firestore Collections
#### Client-accessible
| Collection | Access |
|------------|--------|
| `memberProfiles/{email}` | Read by `uid` or email doc ID. No write. |
| `memberData/{tier}/{uid}/{document=**}` | Read by `uid` in path. No write. |
| `issue_reports/{reportId}` | Create (any auth). Read/update/delete by owner uid. |
| `users/{uid}`, `usage/{uid}`, `userSuites/{uid}`, `userSessions/{uid}` | Owner read/write. |
| `analytics/{document}` | Auth read. No write. |

#### Cloud-function-only (deny-all client rules)
`guests`, `deviceUsage`, `deviceGuestMapping`, `emailCooldown`, `the_qag_registry`, `processed_requests`

#### Suite Storage
- **Firestore metadata:** `memberData/{tier}/{uid}/{date}/suites/{serial}` → `{moduleName, feature, createdAt, updatedAt, uid, date}`
- **GCS test cases:** `memberData/{tier}/{uid}/{date}/suites/{serial}.json` (gzipped, auto-decompressed)
- **Counter:** `memberData/{tier}/{uid}/_counter_suites` → atomic serial number
- **Session:** `memberData/{tier}/{profileUid}/_session` → `{deviceId, lastActive}`

### Cloud Functions Quick Reference
| Function | Auth | Rate Limit | Key Collections |
|----------|------|------------|-----------------|
| `checkSessionByEmail` | No | 10/min/email | `memberProfiles` |
| `registerSession` | Yes | 20/min/uid | `memberData/{tier}/{uid}/_session` |
| `generate` | Yes | 10/min/uid | `usage`, `processed_requests`, DeepSeek |
| `getOrCreateGuestToken` | No | 5/min/deviceId | `deviceGuestMapping`, `guests`, `usage` |
| `linkGoogleAccount` | Yes | 3/min/uid | `memberProfiles`, `guests`, `usage` |
| `deleteAccount` | Yes | 2/min/uid | `emailCooldown`, GCS, `memberData` |
| `pushMemberSuite` | Yes | 30/min/uid | GCS write, `memberData` |
| `getMemberSuites` | Yes | 10/min/uid | GCS read, `memberData` |
| `deleteMemberSuite` | Yes | none | GCS delete, `memberData` |
| `checkGenerationQuota` | Yes | none (cached 10s) | `usage`, `guests` |
| `getMemberDashboard` | Yes | none (cached 10s) | `usage`, `memberProfiles` |

---

### Positioning
QA Genie is **not** a test management tool (TestRail, Zephyr, Qase, Xray) — it's a **generation layer upstream** of them. Target workflow:
1. Open QA Genie → describe a feature → get structured test cases
2. Export to CSV / JSON / Xray format
3. Import into existing test management tool

Users keep their existing ecosystem. QA Genie just removes the painful part — writing test cases from scratch.

---

## 4. Core Rules

### 4.1 Account System
- **Only two types:** `USER` (Google-authenticated) and `GUEST` (anonymous, device-based).
- **Guest subtypes:** First-time → 6 quotas/day. Returning → 1 quota/day (from prior `deviceGuestMapping` or logout/delete).
- Guest creation only on explicit **"Continue as Guest"** tap. Device stays mapped as returning guest via `deviceGuestMapping` (ANDROID_ID keyed, survives data clear).
- Guest → USER: `linkGoogleAccount` **preserves** `deviceGuestMapping` — device never gets first-time guest again.
- **Only `CORE` and `PRO` tiers.** `CORE` is default for all users and guests. Returning guests differ only in 1 quota vs 6.
- `PRO` is **not released** initially. Pricing $6.99. Implementation must be 1-2 tweaks from launch-ready.

### 4.2 Guest Restrictions
- Guests cannot see **Delete Account** or **Logout**.
- Guests cannot submit feedback. Show "Sign in with Google to share your feedback". No redirect to ReportIssueScreen.
- Only **stars** collected from export success dialog of first-time guest.
- Logout → auto move to **new returning guest** (1 quota). No merge on Google link — delete returning guest.

### 4.3 Auth Dialog
- **Not dismissible** by back button. `PopScope(canPop: false)` + `barrierDismissible: false`.
- After multi-device conflict [No] → auth dialog restricted to Google-only via `_forceGoogleOnly` state.
- Button uses `Stack` with both idle/loading rows always rendered (same icon + text + 24px dots spacer, zero layout shift).

### 4.4 Multi-Device Session
1. `checkSessionByEmail` — checks conflict before Google sign-in. No auth. Rate-limited 10/min/email.
2. Conflict dialog **before** `linkWithCredential`. [No] → sign out Google, restrict to Google-only. [Okay] → proceed, old device kicked.
3. `registerSession` — registers device after sign-in. Rate-limited 20/min.
4. `SessionMonitor` — realtime Firestore snapshot on `_session` doc. On `deviceId` change → "Signed in on another device" dialog → `hardSignOut()` → wipe local data → auth dialog.
5. `hardSignOut()`: wipes local DB via `DatabaseService.clearAll()` + `invalidateSuitesCache()`, signs out Google + Firebase, clears prefs (preserves `first_launch_completed`, `never_show_guidelines`, `first_launch_guidelines_shown`). **No guest re-creation.**

### 4.5 Local Database (SQLite)
- **Identity = `DeviceUtils.getUniqueId()`** (ANDROID_ID) for ALL users — guests and members share same DB file.
- **Key tables:** `suites` (id, moduleName, feature, platform, created_at, cloud_id, dirty), `test_cases` (id, suite_id FK, case_json), `reported_issues`, `pending_deletes`.
- `dirty` flag prevents overwriting local edits with stale cloud data.
- `clearAll()` deletes all rows + resets sequences. Does NOT close DB or delete file.

### 4.6 Quota System (Server-Authoritative)
| Type | Free/Day | Rewarded/Day | Cases/Batch | Exports/Day |
|------|----------|-------------|-------------|-------------|
| CORE (user) | 0 | 6 | 10 | 50 |
| PRO (user) | 15 | 0 | 20 | unlimited |
| First-time Guest | 0 | 6 | 10 | 50 |
| Returning Guest | 0 | 1 | 10 | 50 |

- Constants in **two places** (must keep in sync): `lib/app/config/app_config.dart` and `functions/index.prod.js` / `index.dev.js` (lines 13-23).
- Guest quotas: `deviceUsage/{deviceId}`. Member quotas: `usage/{uid}`. Ad reward tokens: `usage/{uid}/usedRewards/{token}`.
- Quota shown **only** in "Generate hint" area. Exhausted popup must show **exact time remaining**.
- Ad-rewarded quotas apply **only to CORE users.**

### 4.7 Generation & AI
- Aim to **always deliver AI-generated test cases.** AI must not fail to produce good test cases.
- **If API call already sent** and we receive nothing → use fallback generator. **No retries**.
- **If API call not sent yet** → can retry AI.
- **Partial Fallback Repair:** Only repair bad cases (same fallback domains). Don't regenerate all.
- Fallback must produce cases **at least 70% similar** to AI-generated.
- `callDeepSeek` always returns (never throws). `HTTP_4xx`/`CLIENT_ERROR` = no-cost. Everything else = quota consumed.

### 4.8 Online / Offline (Production Mode)
- **Online required:** generating test cases, exporting test cases/summary. Show "No Internet" screen.
- **Offline allowed:** editing test cases, checking system assistant, managing test suites.
- **Never** allow offline generations or exports.

### 4.9 Account Deletion & Cool-down
- Delete or Logout → auto move to **new returning-guest** (1 quota).
- Same Google account: **24h cool-down** (global, not device-based). `emailCooldown/{email}` doc.
- Different email on same device: works immediately.
- **No data merge** on guest → member move.
- **Web deletion page:** `qagenies.com/delete-account.html` — email `wipe@qagenies.com`. 24-48h processing. **No take backs.**
- Google Play requires both in-app + web deletion URL.

### 4.10 UI Conventions
- **Dark theme only.** Colors in `app_colors.dart`.
- **No snackbars.** All user-facing messages in **dialog boxes.** Human-readable, never raw errors.
- **Blur:** Always sigma 15, single source via `showBlurredDialog` in `dialog_utils.dart`.
- **Tour:** `BackdropFilter` outside `FadeTransition` (blur persistent across steps). 6-step overlay.
- **Seamless navigation:** No loading indicators or loading screens — ever.

### 4.11 Error Display
- No snackbars in production.
- All dialogs with background blur — sigma 15, single source via `showBlurredDialog` only.
- Messages must be human-readable, never raw errors.

### 4.12 Data Collection & Sync
- **Collect metadata:** email, device ID, etc.
- **Never** collect test cases, modules, or test case content.
- Exception: collect full issue reports.
- **Live sync never performed on test cases.**
- Only synced field: `status` (from `issue_reports`). Frequency: **once every 7 days** (Monday).

### 4.13 Ad Configuration
- **Currently active:** Google test ad unit IDs (`ca-app-pub-3940256099942544/...`).
- **Real IDs (swap at launch):** Publisher `ca-app-pub-5950082050771694` — 3 rewarded, 1 interstitial, 1 native. Commented in `ad_units.dart`.
- **Formats:** Rewarded video only (user-initiated). No interstitials, banners, or native in prod.
- **Preloading:** Exactly one ad must always be preloaded for instant display.
- **Mediation partners:** Unity Ads (already integrated), AppLovin + Mintegral (add at launch via AdMob bidding).

### 4.14 AI In-App Reporting
- Report/flag button accessible from `SuitePreviewScreen` (flag icon → `ReportIssueScreen`).
- `ReportIssueScreen` supports: issue type dropdown, title, description, steps, device info toggle.
- Guests: lock screen → "Sign in with Google to share your feedback".

### 4.15 Policies & Legal
All 5 policies must be **identical** in-app (`legal_documents.dart`) and on website:

| Document | URL | Contact |
|----------|-----|---------|
| Privacy Policy | `qagenies.com/privacy.html` | hello@qagenies.com / chenchuenay@qagenies.com |
| Terms of Service | `qagenies.com/terms.html` | hello@qagenies.com / chenchuenay@qagenies.com |
| AI Disclaimer | `qagenies.com/ai-disclaimer.html` | — |
| Ads & Monetization | `qagenies.com/ads-monetization.html` | hello@qagenies.com / chenchuenay@qagenies.com |
| Delete Account | `qagenies.com/delete-account.html` | wipe@qagenies.com (no take backs) |

---

## 5. Build & Deploy

### Build Practices
- Always: `flutter clean && flutter pub get` before any build.
- Uninstall existing app before installing new APK (`adb uninstall` then `adb install`).
- **Never build with `--dart-define=IS_DEV=true` unless explicitly asked.**

### Git Discipline
- **Never checkout, reset, merge, or switch branches while uncommitted changes exist.** Always `git commit` or `git stash` first.
- Branches: `main`, `dev`, `working` should stay identical during active development. Create `stable-X.Y.Z` tags for releases.

---

## 6. Ontology Engine Reference

### Goal
Replace hardcoded domain templates with a generative ontology engine using entity property definitions — works for any domain without per-domain generator code.

### Key Decisions
- `PropertyDef` is the core abstraction — generators read property types/examples/constraints, not domain names.
- `VariationPool` uses seeded Random for deterministic but varied output.
- `OntologyScenarioPlanner` iterates entity+action pairs with round-robin category cycling.
- Quota consumed **after** DeepSeek call (cost incurred first), with overdraft safety for race conditions.
- Nonce expiry checked **before** DeepSeek call to avoid wasting AI cost.
- `callDeepSeek` always returns (never throws). `HTTP_4xx`/`CLIENT_ERROR` = no-cost.

### Quota Edge Cases
- **SCENARIO 2.2 (Race → Overdraft):** DeepSeek called + ad watched + quota exhausted in same window → one over-limit increment allowed, returns fallback. Quota consumed.
- **SCENARIO 2.3 (No-cost error → free fallback):** `HTTP_4xx`/`CLIENT_ERROR` = `aiNoCost: true`. No counter increment. `freeFallback: true`.
- **SCENARIO 4.5 (Expired nonce → skip DeepSeek):** Nonce >5 min old → atomically consumed, `freeFallback: true`. No AI cost, no quota consumed.

### DeepSeek Config
`timeoutSeconds: 60`, fetch abort at 55s, model `deepseek-v4-flash`, `extra_body: { thinking: { type: "disabled" } }`, `response_format: { type: "json_object" }`.

### 10 Confirmed Domains
Identity → Login/SSO, Commerce → Checkout, Banking → Transfer, Medical → Patient Records, Scheduling → Book Appointment, Integration → Webhook, AI/ML → Model Training, Social → Create Post, Tech → Server Deploy, Robotics → Robot Mission.

### Relevant Files
| File | Purpose |
|------|---------|
| `lib/engine/ontology2/model/` | entity_def, action_def, state_def, domain_ontology, step_template |
| `lib/engine/ontology2/registry/domain_index.dart` | Master registry with `detect()` for all 10 domains |
| `lib/engine/ontology2/registry/domains/` | 10 domain data files |
| `lib/engine/ontology2/generators/` | 5 ontology generators (title, data, step, precondition, expected_result) |
| `lib/engine/ontology2/planners/ontology_scenario_planner.dart` | Scenario planner for V2 engine |
| `lib/engine/orchestrator/deterministic_engine_v2.dart` | V2 orchestrator |
| `lib/engine/orchestration/pipeline_orchestrator.dart` | Hard error logic |
| `lib/engine/orchestration/stages/ai_generation_stage.dart` | freeFallback flag handling |
| `lib/engine/orchestration/stages/fallback_stage.dart` | Uses DeterministicEngineV2 |
| `lib/engine/models/pipeline_models.dart` | GenerationRequest, AiStageResult |
| `functions/index.prod.js` + `index.dev.js` | `exports.generate` with nonce expiry, no-cost errors, overdraft |

---

## 7. Contacts

| Purpose | Email |
|---------|-------|
| General enquiries | hello@qagenies.com |
| Creator | chenchuenay@qagenies.com |
| Account deletion | wipe@qagenies.com (no take backs) |
| Website footer | hello@qagenies.com |
| About screen | chenchuenay@qagenies.com |
