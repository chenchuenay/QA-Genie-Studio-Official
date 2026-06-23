class LegalDocuments {
  static const String siteBaseUrl = 'https://qagenies.com';
  static const String privacyPolicyUrl = '$siteBaseUrl/privacy.html';
  static const String termsOfServiceUrl = '$siteBaseUrl/terms.html';
  static const String aiDisclaimerUrl = '$siteBaseUrl/ai-disclaimer.html';
  static const String adsPolicyUrl = '$siteBaseUrl/ads-monetization.html';

  static const String privacyPolicy = '''
QA Genie Privacy Policy
Last updated: June 22, 2026

1. Data We Collect

Account Identity:
- Guest members: A persistent device identifier (Firebase Installation ID) is used to create a temporary guest token and associate usage with your device. Guest UIDs follow the format guest_{timestamp}_{random}.
- Google Sign-In members: We receive your Firebase UID, email address, and display name from Google. We do not store your password.
- Device ID: Generated from Firebase Installations and cached locally in SharedPreferences. Sent with generation requests for quota enforcement and account operations.

AI Generation:
- When generating test cases, your selected module name, feature name, platform, and prompt notes are sent via our secure cloud function to our AI provider to produce test cases. Prompts are sanitized before transmission (HTML stripped, truncated to 12,000 chars).
- An optional PII scrubber may redact emails, phone numbers, URLs, IP addresses, credit cards, API keys, JWTs, and UUIDs from prompts before they leave your device.

Usage Metrics:
- Generation/export counts (daily), lifetime generated case counts, and reward token consumption records are maintained to enforce fair-use limits.

Issue Reports:
- When you submit feedback or a bug report, we collect: issue type, title, description, optional steps, and (if toggle is ON) device model, app version, and platform. Data is stored locally in SQLite and synced to Firestore.

Analytics:
- Firebase Analytics tracks: app opens, screen views, generation events (started/completed/failed), exports, rewarded ad completions, upgrade interest, and bug report submissions. Parameters include platform, mode, counts, durations, and categories.

AdMob & Mediation:
- Rewarded ads (user-initiated only) may involve collection of advertising identifiers by Google AdMob and its mediated partners (Unity Ads) per their respective privacy policies.

2. Test Case Content & Cloud Sync
When you are signed in with Google, your test suites and their test case content are securely transmitted to our cloud infrastructure (Google Cloud Storage + Firestore) to enable access across your devices. This data is encrypted in transit and at rest.
Guest accounts are local-only — test case content never leaves your device.
We never analyze, train on, or share your test case content with any third party beyond the cloud infrastructure required to operate the sync feature.

3. Third-Party Services
- Firebase (Google): Authentication, Firestore, Cloud Functions, Cloud Storage, Analytics, App Check, Installations
- AI Provider: Test case generation (provider subject to change)
- Google AdMob: Rewarded video advertising, with Unity Ads as a mediated partner

4. Data Security
All communications use HTTPS/TLS encryption. Data stored on our servers is encrypted at rest. Firebase App Check verifies app integrity. Access to your data is restricted by security rules — only you and our backend functions can access your information.

5. Data Retention & Deletion
You can delete your account at any time through the app settings (Account > Delete Account). This removes your profile, usage data, synced test cases, and authentication credentials from our servers. A 24-hour cooldown prevents immediate re-registration of the same Google account.
Local data on your device (SQLite database) must be cleared by uninstalling the app or clearing app data through Android settings.

6. Your Rights
- Access: View your data through the Account screen
- Portability: Export test cases in Excel, CSV, JSON, or PDF
- Deletion: Delete your account as described above
- Ad opt-out: Disable ad personalization via Android Settings > Google > Ads

7. Children's Privacy
QA Genie is not intended for children under 13. We do not knowingly collect personal information from children.

8. Changes to This Policy
We may update this policy from time to time. Continued use after changes constitutes acceptance of the updated policy.

9. Contact
For privacy questions or data deletion requests: chenchuenay@qagenies.com''';

  static const String termsOfUse = '''
Terms of Service
Last updated: June 22, 2026

1. Service Purpose
QA Genie is a hybrid-powered test case generation tool for professional quality assurance and software testing purposes. An active internet connection is required to generate test cases, export test cases, and export summaries. Editing test cases, viewing saved suites, and managing local data may be performed offline. Generated test cases are suggestions only and must be reviewed, validated, and adapted by a qualified human tester.

2. Account Types
- USER: Authenticated via Google Sign-In. Your suites sync across devices via cloud storage.
- GUEST: Anonymous, local-only account. First-time guest gets 6 daily generations; returning guest gets 1. Guest data does not sync.
One person, one account: Account sharing or automated account creation is prohibited.

3. Tiers
- CORE (Free): Default tier for all users and guests. Includes daily quotas and ad-rewarded extra generations.
- PRO (Upcoming): Paid tier with additional features and increased quotas. Pricing announced at launch.

4. Quotas & Fair Use
Daily generation quotas reset at midnight UTC. CORE users may watch rewarded ads for extra same-day generations. Rate limits: max 10 generation requests/minute, 5 issue reports/minute. Abuse results in suspension.

5. Multi-Device Use
You may use the same Google account on multiple devices, but only one device can maintain an active session at a time. When you sign in on a new device, you will be notified if another device holds the session. You may take over or cancel. The previous device will be signed out when it next connects.

6. Account Deletion & Cooldown
Deleting your account removes your profile, synced test cases, and authentication. Your session converts to a returning guest (1 quota). A 24-hour global cooldown prevents the same Google account from being re-registered. You may use a different account immediately.

7. Acceptable Use
You agree not to: submit malicious prompts, extract system prompts, use for illegal purposes, reverse engineer, automate interactions, interfere with servers, create harmful content, or circumvent access controls.

8. Data Processing
All generation requests are processed through Firebase Cloud Functions before reaching the inference provider. Prompts are sanitized and PII-scrubbed before transmission. Idempotency keys prevent duplicate processing. Generated test cases may be synced to cloud storage for multi-device access.

9. AI Output & Validation
Generated test cases are probabilistic — inference models predict patterns, not deterministic logic. Content may contain inaccuracies, missing steps, hallucinated features, or inconsistent data. Human review required before use in production, CI/CD, or compliance testing.

10. Export Formats
Excel (.xlsx), CSV, JSON, and PDF. Exports require an active internet connection.

11. Advertising
Rewarded video ads via Google AdMob with Unity Ads as mediated partner. No interstitial or banner ads.

12. Disclaimer of Warranties
The app is provided "as is." We disclaim all warranties, express or implied, including merchantability, fitness for purpose, and non-infringement.

13. Limitation of Liability
To the maximum extent permitted by law, we shall not be liable for indirect, incidental, or consequential damages arising from use of the app or reliance on generated content.

14. Termination
We may suspend or terminate access for violations of these terms. You may stop using the app at any time and delete your account.

15. Changes
We may update these terms. Continued use after changes constitutes acceptance. Material changes communicated in-app.

16. Governing Law
These terms shall be governed by the laws of India. Disputes subject to the exclusive jurisdiction of courts in Kerala, India.

17. Contact
chenchuenay@qagenies.com''';

  static const String aiDisclaimer = '''
AI Content Disclaimer
Last updated: June 22, 2026

QA Genie utilizes inference models to assist in the creation of test scenarios, test steps, and quality assurance documentation. Please understand the following:

1. Probabilistic Nature
Inference models function by predicting information based on learned patterns rather than absolute, deterministic logic. Generated content may contain: logical inaccuracies or missing steps, incorrect expected results, hallucinated features or behaviors, inconsistent test data.

2. Human Review Required
All generated content MUST be reviewed, validated, and edited by a qualified QA engineer before use in: production test suites, CI/CD pipelines, regulatory or compliance testing, customer-facing deliverables.

3. No Warranty
We disclaim all warranties, express or implied, regarding accuracy, completeness, or fitness for purpose of generated content. We are not liable for defects, outages, or damages arising from use of generated test content.

4. PII Scrubbing
Prompts may be processed by an automated PII scrubber that detects and redacts: email addresses, phone numbers, URLs, IP addresses, credit card numbers, API keys, JWTs, and UUIDs. This is a best-effort mechanism and does not guarantee complete removal of all sensitive data.

5. Fallback Processing
If the primary generation service is unavailable or returns invalid results, the app may fall back to local deterministic generation. These generated cases are simpler and rule-based, not derived from inference models.

6. Your Responsibility
You are solely responsible for the quality and suitability of any testing strategy that incorporates generated content. All generated content should be rigorously reviewed before use in critical software development life cycles.''';

  static const String adsPolicy = '''
Ads & Monetization Policy
Last updated: June 22, 2026

QA Genie operates on a freemium model. Some features require watching a rewarded advertisement.

1. Rewarded Ads (Opt-In)
CORE tier users may unlock additional generation and export capacity by watching rewarded video ads through Google AdMob. Ads are user-initiated only — you choose when to watch. A transaction token is generated upon ad completion and verified server-side.

2. Data & AdMob
By watching a rewarded ad, Google AdMob and its mediated partners (Unity Ads) may collect: advertising ID (Android), device info, IP address, app interaction data. These identifiers are processed per each network's privacy policy. You can opt out of ad personalization via Android Settings > Google > Ads.

3. Ad-Free Pro Tier
PRO tier users experience no ads and bypass all ad-supported limitations. PRO status is managed via internal subscription verification.

4. No Intrusive Ads
We do not serve interstitial, banner, or native ads. The only ad format is rewarded video, triggered only by your explicit action. No pop-ups, no auto-playing ads, no background ad loading.

5. Ad Integrity
Ad completion is verified server-side using a cryptographically random transaction token. Attempting to spoof ad completion or bypass ad requirements violates our Terms of Service and may result in account suspension.

6. Contact
If you believe your PRO status is not correctly applied or you experience issues with rewarded ads, contact us via Support > Report an Issue or email chenchuenay@qagenies.com.''';
}
