### QA GENIE CORE RULES (Structured for AI)

**Immutable Identifiers**

- `PACKAGE_NAME`: `com.enaykumar.qagenie`
- `APPLICATIONID`: `com.enaykumar.qagenie`
- `FIREBASE ID`: `qa-genie-ai`

**Agent Pre‑planning & Fix‑applying Rules**

1. **Account Types**
   - Only two types: `USER` and `GUEST`.
   - Guest sub‑types:
     - _First‑time Guest_ → 6 quotas/day
     - _Returning Guest_ → 1 quota/day

2. **Tiers**
   - Only `CORE` and `PRO` exist.
   - `CORE` is the default for ALL users and ALL guests.
   - Returning guests also have `CORE`, but with only 1 quota (the only difference).

3. **Seamless Navigation**
   - All screen transitions must be lag‑free.
   - No loading indicators or loading screens are ever shown.

4. **Guest Restrictions**
   - Guests cannot see _Delete Account_ or _Logout_.
   - Guests cannot submit feedback. soo no share feedback dailog or not alloud to see report a issue fields but sign in to submit report
   - only stars collected from export success dailog of the first‑time guest (6‑quota guest).
   - user Logout → auto move to new returning guest (1),returning guest is like a temparary account soo no need to murge and when licked to google then delete returning guest

5. **AI Test Case Generation & Fallback**
   - Aim to always deliver AI‑generated test cases. The AI must not fail to produce good test cases.
   - If the API call **has already been sent** and we receive nothing → use the fallback generator. **No retries** in this case.
   - If the API call **has not been sent** yet → we can retry the AI.

6. **Partial Fallback Repair**
   - If the AI returns some good test cases and some bad ones, the fallback generator must **only** repair the bad ones.
   - Use the same fallback generator (with fallback domains) to repair only the failed cases. Do not regenerate all test cases.

7. **Ad Preloading**
   - Exactly one ad must always be preloaded, so ads appear instantly when needed.

8. **Online / Offline Behaviour (Production Mode)**
   - **Online required** for: generating test cases, exporting test cases, exporting a summary. If offline, show a “No Internet” screen.
   - **Offline allowed** for: editing test cases, checking system assistant, checking/editing test suites and saving them.

9. **Account Deletion & Cool‑down**
   - When a user deletes or logs out, they are automatically moved to a **new returning‑guest account** (1 quota).
   - The same Google account that was deleted cannot be used again for **24 hours** (cool‑down is global, not device‑based).
   - On the same device, the user can use a **different email** immediately.
   - If they move from that returning‑guest to a user account, data and quota are **not** merged or reflected from the old account.

10. **Error Display**
    - No snackbars in production. All user‑facing messages must be in **dialog boxes**.
    - Messages must be human‑readable.
    - The system must handle errors gracefully so the user never sees raw errors; only helpful, friendly messages.

11. **Quota Visibility**
    - Quota may be shown **only** in the “Generate hint” area. Nowhere else.
    - When the quota‑exhausted popup appears, it must show the exact time remaining until reset (so the user knows when to return).

12. **Ad‑Rewarded Quotas**
    - Ad‑rewarded quotas apply only to `CORE` users.
    - `CORE` is the default for users and guests, but returning guests differ only in having 1 quota instead of 6.

13. **Data Collection & Sync**
    - Collect metadata: email, device ID, etc. (whatever is needed).
    - **Never** collect test cases, modules, or anything related to test case content.
    - Exception: collect full issue reports.
    - **Live sync** is never performed on test cases.
    - Only one field is synced: `status`.
    - `status` must be linked to Firebase and the app so users can see the current status.
    - Sync frequency: **once every 7 days** only.

14. **Pro Version Strategy**
    - The `PRO` tier is **not released** in the initial build.
    - `PRO` implementation must be **ready** (only one or two modifications needed to launch).
    - Pricing will be decided later (current proposal $6.99), based on user feedback and “pro interest” taps.

15. **Cost & Performance Optimization**
    - Always minimise reads, writes, and checks while delivering full features and full security checks.
    - Batching is allowed, but security takes higher priority.
    - Cost efficiency is a top priority; aim for low cost and high revenue.

16. **Fallback Quality**
    - The fallback generator must produce test cases that appear **at least 70% similar** to AI‑generated test cases.

- 17.we never allow offline generations or exports

### Run Shortcuts (for agents)

##### VERY IMPORTANT

shortcuts for runs -when i said = what i meant
run prod = flutter run --flavor prod -t lib/main.dart --dart-define=MODE=prod
run dev = flutter run --flavor dev -t lib/dev_main.dart --dart-define=MODE=dev

dev is only for testing/developing etc only but prod vaient should for releasing or uploading in playstore

AGENTS SHOULD ACKNWLWDGE IN THE CHAT THAT THEY READ AND FOLLOWING RULES FROM AGENTS.MD
