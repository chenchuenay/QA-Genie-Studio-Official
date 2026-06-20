# QA Genie Privacy Policy

**Last updated: June 18, 2026**

---

## 1. Introduction

QA Genie ("we," "our," "us") provides an AI-powered test case generation tool for quality assurance professionals. We operate on a philosophy of **data minimization** — collecting only what is strictly necessary to deliver the service.

This policy describes what data we collect, how it is processed, and your rights regarding that data.

---

## 2. Data We Collect

### 2.1 Account Identity

Additionally, an **email cooldown** record is created for 24 hours after Google account deletion to prevent immediate re-registration (stored in `emailCooldown/{email}`).

| Data | Collection Method | Purpose |
|------|------------------|---------|
| **Firebase UID** | Firebase Authentication | Account identification, quota enforcement |
| **Email address** | Google Sign-In (if used) | Account association, support contact |
| **Display name** | Google Sign-In / Auto-generated | UI personalization |
| **Device ID** | Firebase Installations + SharedPreferences | Guest identity persistence, quota enforcement, device-specific usage tracking |
| **Auth provider** | Firebase Auth | Account type classification (guest vs. Google-authenticated) |

- **Guest mode**: When using as guest, a persistent device identifier is generated from Firebase Installations and stored locally. This ID is sent to our backend to create a temporary guest token and associate usage with your device.
- **Google Sign-In**: If you choose to link your Google account, we receive your email address and display name from Google. We do **not** store your password.

Storage: Firebase Authentication + Firestore (`users/{uid}`, `guests/{uid}`, `deviceGuestMapping/{deviceId}`, `the_qag_registry/{uid}`)

### 2.2 AI Generation Data

When you generate test cases, the following data is sent to our cloud function and then to our AI provider:

| Data | Example | Purpose |
|------|---------|---------|
| **Module name** | "User Login" | Context for test generation |
| **Feature name** | "Password Reset" | Context for test generation |
| **Platform** | "Android" | Platform-specific test adaptation |
| **Prompt / constraints** | User-entered test notes | Customization of generated cases |
| **Request ID** | UUID | Idempotency (prevents duplicate processing) |
| **Device ID** | Installation ID | Quota enforcement |
| **Ad reward token** (if applicable) | Transaction ID | Verifying ad completion for free-tier usage |

- The prompt is **sanitized** before transmission: HTML tags are stripped, and the prompt is truncated to 12,000 characters.
- An optional PII scrubber (emails, phone numbers, URLs, IPs, credit cards, API keys, JWTs, UUIDs) may redact sensitive patterns before the prompt leaves the device.
- The AI provider receives only the sanitized prompt text — no personal identifiers.
- Generated test cases are returned to the device and stored locally in your SQLite database. Metadata about the generation (counts, mode, success/failure) is stored in Firestore for quota management.

**AI Providers**:
- **Primary**: DeepSeek API (`api.deepseek.com`) — used via Firebase Cloud Function
- **Fallback (development only)**: Google Gemini API — called directly from the client

### 2.3 Usage Metrics

We track aggregated usage data to enforce fair-use limits and improve service quality:

| Metric | Purpose |
|--------|---------|
| Generation count (daily) | Quota enforcement |
| Export count (daily) | Quota enforcement |
| Lifetime generated cases | Usage statistics |
| Last reset timestamp | Daily quota cycle management |
| Pro interest events | Feature interest analytics |
| Export format preferences | Product improvement |
| Reward token consumption | Ad-credit verification |

Storage: Firestore (`usage/{uid}/metrics`, `deviceUsage/{deviceId}`)

### 2.4 Issue Reports

When you submit a bug report or feedback, we collect:

| Data | Source | Required? |
|------|--------|-----------|
| Issue type | User selection (Bug, Feedback, Feature Request, etc.) | Yes |
| Title | User-entered text | Yes |
| Description | User-entered text | Yes |
| Steps to reproduce | User-entered text (optional) | No |
| Device model | Auto-detected (`device_info_plus`) | Optional |
| App version | Auto-detected (`package_info_plus`) | Optional |
| Platform | Auto-detected | Optional |
| Screen name | Auto-detected | Yes |
| Firebase UID | Auto-attached | Yes |

If the cloud submission fails, the report is stored locally in SQLite and synced when connectivity is restored.

Storage: Locally in SQLite (`reported_issues` table) + Firestore (`issue_reports/{id}`)

### 2.5 Device Information

| Data | Source | Usage |
|------|--------|-------|
| Device model (e.g., "Pixel 7") | `device_info_plus` | Issue report diagnostics |
| App version | `package_info_plus` | Issue report diagnostics |
| Platform (Android) | Runtime detection | Issue report diagnostics, analytics |
| Firebase Installation ID | Firebase Installations SDK | Device identification for guest auth |

### 2.6 Firebase Analytics Events

We use Firebase Analytics to understand app usage patterns. The following events are logged:

- `app_open` — App launch
- `generation_started` — with platform, mode, requested_count
- `generation_completed` — with platform, mode, generated_count, duration_ms
- `generation_failed` — with platform, mode, reason
- `export_completed` — with format, case_count
- `rewarded_ad_completed` — with placement
- `upgrade_intent` — with source
- `bug_report_submitted` — with category
- Screen views — screen name tracking

Firebase Analytics may collect device identifiers, IP addresses, and usage data per Google's privacy policy. Analytics can be disabled via the `firebase_analytics` opt-out mechanism.

### 2.7 AdMob (Rewarded Ads)

We serve rewarded video advertisements via Google AdMob. When you choose to watch a rewarded ad:

- AdMob may collect **advertising identifiers** (Android Advertising ID)
- AdMob may collect **device information**, **IP address**, and **app usage data**
- A **transaction token** is generated locally and sent to our backend to verify ad completion and credit your account

AdMob data handling is governed by Google's Privacy Policy. You may opt out of ad personalization in your device settings.

### 2.8 Local-Only Data (Not Collected by Us)

The following data remains **entirely on your device** in a SQLite database (`qa_genie.db`) and is never transmitted to our servers:

- Generated test cases (full content with steps, expected results, etc.)
- Test suite metadata (module name, feature, platform)
- Offline issue reports (queued for sync)
- Cached prompt data
- App preferences (first-launch flags, guideline dismissals, update dismissal count)
- Locally generated test cases (DeterministicEngine fallback)

## 3. Third-Party Services

| Service | Provider | Purpose | Data Shared |
|---------|----------|---------|-------------|
| **Firebase Authentication** | Identity platform | Account management | Firebase UID, email (if Google sign-in) |
| **Cloud Firestore** | Database | Usage/quota data, issue reports | Usage metrics, device ID, issue data |
| **Cloud Functions** | Serverless compute | AI generation, quota verification, tracking | Prompt text, module/feature, device ID, usage data |
| **Firebase Analytics** | Analytics | Usage analytics | Event data, device info, IP address |
| **Firebase App Check** | Security | App attestation | App identity |
| **Firebase Installations** | Device identification | Installation ID | Installation identifier |
| **DeepSeek API** | AI provider | Test case generation | Sanitized prompt text |
| **Google AdMob** | Advertising | Rewarded ads | Advertising ID, device info, IP address |

## 4. Data Storage and Security

- **In transit**: All network communications use HTTPS/TLS encryption
- **At rest (server)**: Firestore data is encrypted at rest per Google Cloud's default encryption
- **At rest (local)**: SQLite database stored in the app's secure application support directory
- **Authentication**: Firebase Authentication with custom tokens for guests; Google Sign-In for authenticated users
- **App attestation**: Firebase App Check is enabled to verify app integrity
- **Security rules**: Firestore is locked down per security rules — users can only access their own data; backend collections are restricted to Cloud Functions only

## 5. Data Retention

- **Usage metrics**: Retained as long as the account exists
- **Email cooldown**: Email address retained for 24 hours after Google account deletion to prevent immediate re-registration
- **Issue reports**: Retained for troubleshooting purposes; deleted upon account deletion
- **Guest tokens**: Mapped to device ID; retained until account deletion or after the deletion cooldown period expires
- **Firebase Analytics data**: Retained per Google Analytics data retention settings (default 14 months)
- **AdMob data**: Governed by Google's AdMob policies
- **Local SQLite data**: Persists until app uninstall or manual clear

## 6. Data Deletion

You can delete your account and associated data at any time:

- **In-app**: Open QA Genie → Account → tap **Delete Account**
- **Web**: Visit [qa-genie-ai.web.app](https://qa-genie-ai.web.app/) and follow the instructions
- **Email**: Send a deletion request to [qagenieai@gmail.com](mailto:qagenieai@gmail.com?subject=Account%20Deletion%20Request)
- **Process**: We delete your Firestore documents (`users/{uid}`, `guests/{uid}`, `usage/{uid}`, `the_qag_registry/{uid}`), de-link device mapping, anonymize issue reports, and delete your Firebase Authentication account

**Note**: Data generated exclusively on your device (local SQLite) must be deleted by clearing app data or uninstalling the app. We cannot remotely wipe local device storage.

## 7. Your Rights

- **Access**: You can view your data via the Account screen
- **Portability**: Your test cases can be exported in Excel, CSV, JSON, or PDF format
- **Deletion**: Request account deletion as described above
- **Opt-out of analytics**: Analytics can be disabled via the FirebaseAnalytics opt-out API
- **Ad personalization opt-out**: Configure via Android device Settings → Google → Ads

## 8. Children's Privacy

QA Genie is not directed at children under 13 (or under 16 in the EU/UK). We do not knowingly collect personal information from children. If we learn that a child has provided personal data, we will delete it promptly.

## 9. AI Disclaimer

Test cases generated by AI models are probabilistic in nature and may contain errors, inaccuracies, or hallucinations. All generated content should be reviewed by a qualified QA professional before use in any testing or production environment.

## 10. Policy Updates

We may update this policy from time to time. Material changes will be communicated via the app. Continued use after changes constitutes acceptance of the updated policy.

## 11. Contact

For privacy questions, data deletion requests, or concerns:
- **In-app**: Support menu → Report an Issue
- **Email**: [qagenieai@gmail.com](mailto:qagenieai@gmail.com?subject=Privacy%20Question)
