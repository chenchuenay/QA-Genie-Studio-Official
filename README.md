# QA Genie

> AI‑powered test case generator that exports to every major test management format — Excel, Jira, Xray, Zephyr, and PDF.

---

## 🚀 Overview

QA Genie transforms feature specifications into structured, industry‑standard test cases using Google Gemini AI.  
It runs entirely on‑device (offline editing, local history) and exports to the exact CSV/XLSX formats expected by Jira, Xray, and Zephyr Scale — without requiring any test management tool.

## ✨ Core Features

- **AI Test Case Generation** – single API call to Gemini Flash, single source‑of‑truth structured JSON
- **Structured Steps** – every step includes `action`, `test data`, and `expected result`
- **Export Engine** – 6 export targets:
  - Excel (traditional table)
  - Jira Native CSV
  - Xray Standard CSV
  - Xray Expanded CSV (step‑per‑row)
  - Zephyr Scale Cloud CSV
  - PDF (styled, branded)
- **Editable Preview** – inline editing with Undo / Save
- **History & Suites** – all generated suites stored locally (SQLite), reopen/edit/export at any time
- **Free / Pro Tiers** – free tier with ads, Pro tier with unlimited exports & higher limits
- **Bug Report System** – direct submission to Firebase Firestore (text only)
- **Email Link Authentication** – password‑less (or Google Sign‑In), ties limits to a verified identity
- **Ad‑supported free tier** – interstitial, banner, rewarded (mock in dev mode)

## 🏗 Architecture
UI (Flutter)
↓
Use Cases (Generate, Save, Export, GetHistory)
↓
Repositories & Data Sources
├── API Client (Gemini) ← only HTTP call
├── Export Mapper ← adapts structured JSON → tool formats
├── Excel / CSV / PDF Writer
├── SQLite Database ← local suites & test cases
└── Monetization Manager ← limits, Pro status, fingerprint



### Design Principles
- **Single Source of Truth** – AI returns structured JSON; all exports derive from one model
- **Only one API call per batch** – generation is the sole network request; everything else is 100% local
- **Clean separation** – UseCase layer isolates business logic; UI never touches databases or API keys directly
- **Test / Production toggle** – `AppConfig.isProduction` switches between free‑for‑all testing and real limits/ads

## 🧱 Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| AI Backend | Google Gemini Flash (via REST) |
| Auth | Firebase Authentication (Email Link, Google Sign‑In) |
| Bug Reports | Cloud Firestore |
| Ads | Google AdMob (interstitial, banner, rewarded) |
| Local DB | SQLite (sqflite) |
| Export | `excel` package, custom CSV writer, `pdf` package |
| Secure Storage | flutter_secure_storage |
| Device Fingerprint | device_info_plus + package_info_plus |
| State Management | setState (simple) + planned Cubit migration |

## 📂 Project Structure
lib/
├── main.dart
├── core/
│ ├── config/ # AppConfig (production/test switch)
│ ├── theme/ # Colors, spacing, text styles
│ ├── ads/ # AdMob service with mock support
│ ├── network/ # Gemini API client
│ ├── monetization/ # Usage limits, Pro flag, export policy
│ ├── use_cases/ # Business logic (generate, save, export, history)
│ └── export/ # Format mappers, Excel/CSV/PDF writers
├── data/
│ ├── models/ # TestCaseModel, TestStep
│ └── database/ # SQLite service (suites, test cases)
└── presentation/
├── screens/ # Home, Preview, History, Upgrade, Bug Report, Login
├── widgets/ # MasterTable, ExportBottomSheet, dialogs
└── animations/ # Shimmer, loading button


## 🔮 Future Roadmap

### Phase 2 – Cloud Sync & Collaboration
- Firestore‑based test suites (sync across devices)
- Move / copy test cases between suites
- Team sharing (read‑only, contributor roles)

### Phase 3 – Test Execution & Reporting
- Actual results & pass/fail tracking per step
- Test summary reports (PDF / Excel)
- Link bugs to specific test cases

### Phase 4 – CI/CD Integration
- Webhook triggers for test generation
- Jira/Xray API direct integration (no file upload)
- CLI companion tool

## ⚙️ Setup (Development)

1. Clone the repository
2. Run `flutter pub get`
3. Set `AppConfig.isProduction = false` for test mode (no Firebase needed)
4. For production:
   - Create a Firebase project and add `google-services.json`
   - Run `flutterfire configure`
   - Set `AppConfig.isProduction = true`
   - Replace ad unit IDs in `app_config.dart` with real AdMob IDs

---

## 👤 Contact
Developer: **Enay Kumar**  
Email: chenchuenay97@gmail.com

---

*QA Genie – Turn Features into Test Cases, Instantly.*