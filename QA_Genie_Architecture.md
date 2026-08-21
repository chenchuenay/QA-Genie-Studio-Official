# QA Genie Studio Architecture Overview

QA Genie Studio is a modular, AI-powered test case generation application. This document serves as the single source of truth for the project's architecture, business logic, and data flows.

## 1. High-Level Directory Structure
- `lib/app/`: Configuration, routing, dependency injection (`app_dependencies.dart`), and themes.
- `lib/core/`: Environment, database services, error handling, security, and utilities.
- `lib/data/`: Data layer (repositories, DTOs).
- `lib/domain/`: Business entities and use cases.
- `lib/engine/`: Core generation pipeline (prompts, planners, orchestrator, deterministic fallback).
- `lib/features/`: Modularized features (Account, Auth, Generation, Monetization, Suites).
- `lib/firebase/`: Firebase integration (Cloud Functions client, Analytics, AppCheck).
- `lib/shared/`: Shared UI components.
- `functions/`: Server-side Node.js logic (AI API integration, quota enforcement).

## 2. Core Architectural Patterns
- **Clean/Feature-based Architecture:** Separation between Domain (logic), Data (repositories), and UI. Features act as self-contained modules.
- **Use Case Orchestration:** Complex operations are encapsulated in `lib/domain/usecases/`.
- **Backend-Driven Logic:** Quotas and core business constraints are enforced server-side in `functions/index.js` to ensure integrity.

## 3. Monetization: Core vs. Pro
Monetization and usage quotas are centralized in `functions/index.js`.

| Feature | Core User | Pro User |
| :--- | :--- | :--- |
| **Daily Generations** | 6 (Rewarded Ad required) | 15 (Free) |
| **Cases per Batch** | 10 | 20 |
| **Daily Exports** | 50 | Unlimited |

*   **Logic:** The `generate` function performs a transactional check against the user's Firestore usage document to determine if the daily quota has been met, applying either Core or Pro constraints based on the plan type.

## 4. User & Guest Lifecycle
- **Guest Mode:**
    - Persistent per device using `deviceGuestMapping` in Firestore.
    - Uses a custom auth token.
    - Limited to rewarded ad generations only.
- **Account Linking (Upgrade):**
    - Guests can link a Google account via `AuthService.linkWithGoogle`.
    - Backend `linkGoogleAccount` function handles the transition, merging usage metrics from the guest profile to the new user profile, and enforcing cooldowns on account deletion.
- **Account Deletion:**
    - Permanently removes all user data and Firestore records.
    - Enforces a 24-hour cooldown period before the same Google email can be re-registered on the same device.

## 5. Data Flow: Generation Pipeline
1. **Request:** `HomeScreen` triggers `GenerateTestCasesUseCase` (passing `adToken` if Core).
2. **Orchestration:** `PipelineOrchestrator` calls the `generate` Cloud Function.
3. **Server Security/Quota:** `index.js` checks:
    - `adToken` validity (if required).
    - Daily generation quota for Pro/Core/Guest.
    - Firestore transaction to increment usage metrics and update global analytics.
4. **AI Generation:** Calls the DeepSeek API.
5. **Validation/Parsing:** AI response is parsed and transformed into standard `TestStep` structures.
6. **Persistence:** Suite is saved via `SaveSuiteUseCase`.

## 6. Key Security & Compliance
- **Forensics/Tracing:** Every generation request is traced with a unique ID for end-to-end debugging.
- **Input Sanitization:** Performed on both the client (UI input validators) and server (prompt construction).
- **Rate Limiting:** Server-side enforcement of generation limits.
- **Compliance:** 90-second watchdog timers are used during rewarded ad display to ensure application stability and AdMob compliance.
