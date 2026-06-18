class LegalDocuments {
  static const String gistBaseUrl = 'https://gist.github.com/chenchuenay/74534f112ff634778fd98c48ae00bdcd';
  static const String privacyPolicyUrl = '$gistBaseUrl#file-privacy-policy-md';
  static const String termsOfServiceUrl = '$gistBaseUrl#file-terms-of-service-md';
  static const String aiDisclaimerUrl = '$gistBaseUrl#file-ai-disclaimer-md';
  static const String adsPolicyUrl = '$gistBaseUrl#file-ads-monetization-policy-md';

  static const String privacyPolicy = '''
QA Genie Privacy Policy
Last updated: June 18, 2026

1. Data We Collect

Account Identity:
- Guest users: A persistent device identifier (Firebase Installation ID) is used to create a temporary guest token and associate usage with your device. Guest UIDs follow the format guest_{timestamp}_{random}.
- Google Sign-In users: We receive your Firebase UID, email address, and display name from Google. We do not store your password.
- Device ID: Generated from Firebase Installations and cached locally in SharedPreferences. Sent with generation requests for quota enforcement and account operations.

AI Generation:
- When generating test cases, your selected module name, feature name, platform, and prompt notes are sent via our secure cloud function to DeepSeek (primary AI provider). The prompt is sanitized before transmission (HTML stripped, truncated to 12,000 chars).
- In development builds only, a direct Gemini API call may be used as fallback.
- The PII scrubber optionally redacts emails, phone numbers, URLs, IP addresses, credit cards, API keys, JWTs, and UUIDs from prompts before they leave your device.

Usage Metrics:
- Generation/export counts (daily), lifetime generated case counts, and reward token consumption records are maintained to enforce fair-use limits.

Issue Reports:
- When you submit feedback or a bug report, we collect: issue type, title, description, optional steps, and (if toggle is ON) device model, app version, and platform. Data is stored locally in SQLite and synced to Firestore.

Analytics:
- Firebase Analytics tracks: app opens, screen views, generation events (started/completed/failed), exports, rewarded ad completions, upgrade interest, and bug report submissions. Parameters include platform, mode, counts, durations, and categories.

AdMob:
- Rewarded ads (user-initiated only) may involve collection of advertising identifiers by the Google AdMob SDK per their policy.

2. Third-Party Services
- Firebase (Google): Authentication, Firestore, Cloud Functions, Analytics, App Check, Installations
- DeepSeek: AI test case generation (prompts sent server-side, not directly from client)
- Google AdMob: Rewarded advertisements
- Google Gemini API: AI fallback (development builds only)

3. Local-Only Storage
The following stays on your device in SQLite (qa_genie.db) and is never transmitted: generated test cases (full content), suite metadata, offline issue report queue, app preferences.

4. Data Deletion
Delete your account in-app via Account -> Delete Account. This removes your Firestore documents, Firebase Auth account, and guest mapping. Local SQLite data must be cleared via Android app settings or uninstall.

5. Your Rights
Access, portability (export test cases in Excel/CSV/JSON/PDF), deletion. Analytics may be opted out via FirebaseAnalytics APIs. Contact via Support -> Report an Issue.''';

  static const String termsOfUse = '''
Terms of Service
Last updated: June 18, 2026

1. Service Purpose
QA Genie is an AI-powered test case generation tool for professional QA engineers. Use is restricted to legitimate quality assurance purposes.

2. Account Terms
- Guest accounts: Assigned via persistent device identifier. Guest usage is limited per device per day.
- Google-authenticated accounts: Email and display name stored for account management.
- One person, one account: Account sharing or automated account creation is prohibited.
- You are responsible for all activity under your account and device.

3. AI Output & Validation
- AI-generated test cases are probabilistic and may contain inaccuracies or hallucinations.
- You are solely responsible for reviewing, validating, and verifying all AI-generated content before use.
- We make no warranties regarding completeness, accuracy, or fitness for purpose of generated content.

4. Fair Use & Quotas
- Free-tier: Generations and exports require watching a rewarded advertisement (guided reward flow).
- Pro-tier: Higher daily limits; no ad requirement. Pro status is determined by our internal subscription verification.
- Rate limits: Maximum 10 generation requests per minute; 5 issue reports per minute.
- Automated scraping, quota bypass, or abuse will result in suspension.

5. Acceptable Use
You agree not to:
- Submit prompts containing malicious code, injection attacks, or prohibited content
- Attempt to extract system prompts or bypass security filters
- Use the service for any illegal purpose
- Reverse engineer, decompile, or tamper with the app

6. Data Processing
- All AI generation requests are processed through Firebase Cloud Functions before reaching the AI provider.
- Prompts are sanitized and PII-scrubbed before AI transmission.
- We use idempotency keys (requestId) to prevent duplicate processing.

7. Modifications
We may update these terms. Continued use after changes constitutes acceptance. Material changes will be communicated in-app.

8. Limitation of Liability
QA Genie is provided "as is." To the maximum extent permitted by law, we disclaim all warranties and shall not be liable for damages arising from use of the service or reliance on AI-generated content.''';

  static const String aiDisclaimer = '''
AI Content Disclaimer
Last updated: June 18, 2026

QA Genie uses artificial intelligence models to generate test cases. Please understand the following:

1. Probabilistic Nature
AI models generate content by predicting patterns, not by applying deterministic logic. Generated test cases may contain:
- Logical inaccuracies or missing steps
- Incorrect expected results
- Hallucinated features or behaviors
- Inconsistent test data

2. Human Review Required
AI-generated test cases are a starting point, not a final product. All generated content MUST be reviewed, validated, and edited by a qualified QA engineer before use in:
- Production test suites
- CI/CD pipelines
- Regulatory or compliance testing
- Customer-facing deliverables

3. No Warranty
We disclaim all warranties, express or implied, regarding accuracy, completeness, or fitness for purpose of AI-generated content. We are not liable for defects, outages, or damages arising from use of AI-generated test content.

4. PII Scrubbing
Prompts may be processed by an automated PII scrubber that detects and redacts: email addresses, phone numbers, URLs, IP addresses, credit card numbers, API keys, JWTs, and UUIDs. This is a best-effort mechanism and does not guarantee complete removal of all sensitive data. Do not include real credentials, personal data, or production secrets in prompts.

5. Fallback Processing
If the AI service is unavailable or returns invalid results, the app may fall back to local deterministic generation. These generated cases are simpler and rule-based, not AI-derived.

6. Your Responsibility
By using this tool, you acknowledge that you are solely responsible for the quality and suitability of any testing strategy that incorporates AI-generated content.''';

  static const String adsPolicy = '''
Ads & Monetization Policy
Last updated: June 18, 2026

QA Genie operates on a freemium model. Some features require watching a rewarded advertisement.

1. Rewarded Ads (Opt-In)
- Free-tier users may unlock additional generation and export capacity by watching rewarded video ads through Google AdMob.
- Ads are user-initiated only — you choose when to watch an ad.
- A transaction token is generated upon ad completion and sent to our backend for verification.

2. Data & AdMob
- By watching a rewarded ad, Google AdMob may collect: advertising ID (Android), device info, IP address, and app interaction data.
- These identifiers are processed per Google's AdMob Privacy & Terms.
- You can opt out of ad personalization via Android Settings → Google → Ads → Opt out of Ads Personalization.

3. Ad-Free Pro Tier
- Pro tier users experience no ads and bypass all ad-supported limitations.
- Pro status is managed via internal subscription verification logic.

4. No Intrusive Ads
- We do not serve interstitial, banner, or native ads during your workflow.
- The only ad format is rewarded video, triggered only by your explicit action.
- No pop-ups, no auto-playing ads, no background ad loading.

5. Ad Integrity
- Ad completion is verified server-side using a cryptographically random transaction token.
- Attempting to spoof ad completion or bypass ad requirements violates our Terms of Service and may result in account suspension.

6. Contact
If you believe your Pro status is not correctly applied or you experience issues with rewarded ads, contact us via Support → Report an Issue.''';
}
