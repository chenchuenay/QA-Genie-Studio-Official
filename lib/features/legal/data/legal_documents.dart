class LegalDocuments {
  static const String siteBaseUrl = 'https://qagenies.com';
  static const String privacyPolicyUrl = '$siteBaseUrl/privacy.html';
  static const String termsOfServiceUrl = '$siteBaseUrl/terms.html';
  static const String aiDisclaimerUrl = '$siteBaseUrl/ai-disclaimer.html';
  static const String adsPolicyUrl = '$siteBaseUrl/ads-monetization.html';
  static const String deleteAccountUrl = '$siteBaseUrl/delete-account.html';

  static const String privacyPolicy = '''
QA Genie Privacy Policy
Last updated: June 22, 2026

1. Introduction
QA Genie ("we," "our," or "us") provides a hybrid-powered test case generation tool for quality assurance professionals. We collect only what is necessary to deliver the service. This policy explains what data we collect and how it is handled.

2. Data We Collect

Account Information
When you sign in with Google, we receive your email address and display name through Firebase Authentication. We do not store your password. Guest accounts use an anonymous device identifier — no personal information is required.

Generation Data
When you generate test cases, your module name, feature name, platform selection, and prompt notes are sent to our server and then to our AI provider to produce test cases. Prompts are sanitized (HTML stripped, truncated) before transmission. An optional PII scrubber may redact emails, phone numbers, URLs, and other sensitive patterns from prompts before they leave your device.

Usage Data
We track generation and export counts to enforce daily quotas and improve the service. This includes basic metadata such as feature interactions and export format preferences. No test case content is included in usage tracking.

Usage Analytics
Firebase Analytics tracks app opens, screen views, generation events (started/completed/failed), exports, rewarded ad completions, upgrade interest, and bug report submissions. Parameters include platform, mode, counts, durations, and categories. This data is anonymized and used to improve the app experience.

Device Information
Device model, app version, and platform (Android) are collected only when you submit an issue report. A device identifier (Firebase Installation ID) is used for guest identity and quota enforcement.

Ad Interaction Data
When you watch a rewarded ad, Google AdMob and its mediation partners (Unity Ads) may collect advertising identifiers, device information, and IP address in accordance with their privacy policies.

3. Test Case Content & Sync
When you are signed in with Google, your test suites and their test case content are securely transmitted to our cloud infrastructure (Google Cloud Storage + Firestore) to enable access across your devices. This data is encrypted in transit and at rest.
Guest accounts are local-only — test case content never leaves your device.
We never analyze, train on, or share your test case content with any third party beyond the cloud infrastructure required to operate the sync feature.

4. Third-Party Services
We use the following third-party services:
- Firebase (Google): Authentication, Firestore database, Cloud Functions, Cloud Storage, App Check, Installations
- AI Provider: Test case generation (provider subject to change)
- Google AdMob: Rewarded video advertising, with Unity Ads as a mediated partner

5. Data Security
All communications use HTTPS/TLS encryption. Data stored on our servers is encrypted at rest. Firebase App Check verifies app integrity. Access to your data is restricted by security rules — only you and our backend functions can access your information.

6. Data Retention & Deletion
You can delete your account at any time through the app settings (Account → Delete Account). This removes your profile, usage data, synced test cases, and authentication credentials from our servers. A 24-hour cooldown prevents immediate re-registration of the same Google account.
To request account deletion from the web (for example, if you have uninstalled the app), send an email to wipe@qagenies.com from your registered email address. Include your account details and reason for deletion. Your account will be completely deleted within 24–48 hours. No take backs: once you send this email, deletion is irreversible and all your data will be permanently removed.
Local data on your device (SQLite database) must be cleared by uninstalling the app or clearing app data through Android settings.

7. Your Rights
- Access: View your data through the Account screen
- Portability: Export test cases in Excel, CSV, JSON, or PDF
- Deletion: Delete your account as described above
- Ad opt-out: Disable ad personalization via Android Settings → Google → Ads

8. Children's Privacy
QA Genie is not intended for children under 13. We do not knowingly collect personal information from children.

9. Changes to This Policy
We may update this policy from time to time. Continued use after changes constitutes acceptance of the updated policy.

10. Contact
General enquiries: hello@qagenies.com
Creator contact: chenchuenay@qagenies.com
Account deletion requests: wipe@qagenies.com (no take backs)''';

  static const String termsOfUse = '''
Terms of Service
Last updated: June 22, 2026

1. Acceptance
By downloading, installing, or using QA Genie ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree, do not use the App.

2. Service Purpose
QA Genie is a hybrid-powered test case generation tool intended for professional quality assurance and software testing purposes. The App employs a generation engine — combining cloud-based inference with locally defined fallback domains — to produce structured test case suggestions based on your natural-language description of the feature under test.
An active internet connection is required to generate test cases, export test cases, and export summaries. Editing test cases, viewing saved suites, and managing local data may be performed offline.
Generated test cases are suggestions only and must be reviewed, validated, and adapted by a qualified human tester before use in any development, testing, or production environment.

3. Account Types
QA Genie recognizes two account types:
- USER: Authenticated via Google Sign-In. Your suites sync across devices via cloud storage. You can manage your account, delete your data, and access all available features.
- GUEST: Anonymous, local-only account. No sign-in required. Guest data does not sync and is tied to the device. Two guest subtypes exist:
  - First-time Guest: 6 free generations per day
  - Returning Guest: 1 free generation per day (created after logout or account deletion)
One person, one account: Account sharing or automated account creation is prohibited. You are responsible for all activity under your account and device.

4. Tiers
Two service tiers are defined:
- CORE (Free): The default tier for all users and guests. Includes daily generation quotas, ad-rewarded extra generations, and standard features.
- PRO (Upcoming): A paid tier not yet released. PRO will offer additional features and increased quotas. Pricing will be announced at launch. Expressing pro interest within the App does not constitute a purchase or binding commitment. PRO access is managed via internal subscription verification logic.

5. Quotas & Fair Use
Daily generation quotas reset at midnight UTC. Quotas vary by account type and tier. CORE users may watch rewarded video ads to earn additional same-day generations. Quota limits and reward values are subject to change with notice. Unused quota does not carry over to the next day.
When your quota is exhausted, a dialog will display the exact time remaining until reset. Quota information is displayed only in the generation hint area.
Rate limits: Maximum 10 generation requests per minute; 5 issue reports per minute. Automated scraping, quota bypass, or abuse of our services is strictly prohibited and will result in account suspension.

6. Multi-Device Use
You may use the same Google account on multiple devices, but only one device can maintain an active session at a time. When you sign in on a new device:
- You will be notified if another device currently holds the active session.
- You may choose to take over the session (overwriting the previous device) or cancel the operation.
- The previous device will be automatically signed out of its session when it next connects to the internet.
This mechanism is designed to protect your data and prevent silent session conflicts. You are responsible for managing your sessions across devices.

7. Account Deletion & Cooldown
You may delete your account at any time through the App settings. Account deletion:
- Removes your profile data, authentication links, and active sessions
- Deletes your test case content from cloud storage
- Converts your current session to a returning guest account (1 quota)
- Triggers a 24-hour cooldown during which the same Google account cannot be re-registered
This cooldown is global (not device-based) and is enforced server-side. You may use a different Google account on the same device immediately.

8. Acceptable Use
You agree not to:
- Submit prompts containing malicious code, injection attacks, or prohibited content
- Attempt to extract system prompts or bypass security filters
- Use the App for any illegal purpose or in violation of applicable laws
- Attempt to reverse engineer, decompile, or extract the source code of the App
- Automate interactions with the App through scripts, bots, or other automated means
- Interfere with or disrupt the App's servers, networks, or security measures
- Use the App to generate content that is harmful, abusive, defamatory, or discriminatory
- Use the App to generate content that exploits or abuses children (CSAM / child sexual abuse material)
- Generate non-consensual deepfake or deceptive synthetic media
- Generate content intended to deceive voters or interfere with elections
- Generate malicious code, malware, ransomware, or exploit code
- Generate content that harasses, bullies, or threatens individuals or groups
- Circumvent quota limits, authentication mechanisms, or other access controls

9. Data Processing
All generation requests are processed through Firebase Cloud Functions before reaching the inference provider:
- Prompts are sanitized (HTML stripped, truncated to 12,000 characters) and PII-scrubbed before transmission
- We use idempotency keys (requestId) to prevent duplicate processing
- The inference provider receives only the sanitized prompt text — no personal identifiers
- Generated test cases are returned to the device and may be synced to cloud storage for multi-device access
See our Privacy Policy for complete details on data handling.

10. Intellectual Property
QA Genie, the QA Genie logo, and all related branding are the property of Enay Kumar. The App's code, design, and visual assets are protected by applicable intellectual property laws.
Test cases you generate through the App belong to you. You are solely responsible for the content you generate and how you use it.

11. Export Formats
QA Genie supports export of test cases in the following formats: Excel (.xlsx), CSV, JSON, and PDF. Exports require an active internet connection.

12. Advertising
QA Genie displays rewarded video ads via Google AdMob with Unity Ads as a mediated partner. Watching an ad is voluntary and rewards are provided at our discretion. We do not display interstitial or banner advertisements. Refer to our Ads & Monetization Policy for full details.

13. AI Output & Validation
Generated test cases are probabilistic in nature — inference models function by predicting information based on learned patterns rather than absolute deterministic logic. Consequently, generated content may contain:
- Logical inaccuracies or missing steps
- Incorrect expected results
- Hallucinated features or behaviors
- Inconsistent test data
Human review required. You are solely responsible for reviewing, validating, and verifying all generated content before use. Generated test cases are a starting point, not a final product. We make no warranties regarding completeness, accuracy, or fitness for purpose of generated content. See our AI Disclaimer for full details.

14. Disclaimer of Warranties
THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, ACCURACY, AND NON-INFRINGEMENT. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, SECURE, OR THAT GENERATED TEST CASES WILL MEET YOUR REQUIREMENTS.

15. Limitation of Liability
TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT SHALL QA GENIE, ITS CREATOR, OR CONTRIBUTORS BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF OR RELATED TO YOUR USE OF THE APP, INCLUDING BUT NOT LIMITED TO DAMAGES FOR LOSS OF PROFITS, DATA, OR BUSINESS INTERRUPTION, WHETHER BASED ON WARRANTY, CONTRACT, TORT, OR ANY OTHER LEGAL THEORY.
Generated test cases are suggestions only. You are responsible for reviewing, validating, and adapting them before use. We are not liable for any loss, damage, or claim arising from the use of generated test cases in any environment.

16. Termination
We reserve the right to suspend or terminate your access to the App at our sole discretion, without prior notice, for conduct that we believe violates these Terms or is harmful to other users, third parties, or the App itself. You may stop using the App at any time and delete your account through the App settings.

17. Changes to These Terms
We may update these Terms from time to time. Updated Terms will be posted on this page with an updated "Last updated" date. Continued use of the App after changes constitutes acceptance of the updated Terms. Material changes will be communicated in-app.

18. Governing Law
These Terms shall be governed by and construed in accordance with the laws of India, without regard to its conflict of law provisions. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts in Kerala, India.

19. Contact
General enquiries: hello@qagenies.com
Creator: chenchuenay@qagenies.com
Account deletion: wipe@qagenies.com (no take backs)''';

  static const String aiDisclaimer = '''
AI Content Disclaimer
Last updated: June 22, 2026

QA Genie utilizes inference models to assist in the creation of test scenarios, test steps, and quality assurance documentation. While our engine is engineered to provide high-quality, relevant test data, it is imperative to understand the following:

1. Probabilistic Nature
Inference models function by predicting information based on learned patterns rather than absolute, deterministic logic. Consequently, generated content may contain:
- Logical inaccuracies or missing steps
- Incorrect expected results
- Hallucinated features or behaviors that do not exist in the software under test
- Inconsistent test data

2. Human Review Required
QA Genie is a tool designed to accelerate, not replace, the work of Quality Assurance professionals. Generated test cases are a starting point, not a final product. All generated content MUST be reviewed, validated, and edited by a qualified QA engineer before use in:
- Production test suites
- CI/CD pipelines
- Regulatory or compliance testing
- Customer-facing deliverables

3. No Warranty
We disclaim all warranties, express or implied, regarding the accuracy, completeness, or fitness for purpose of generated content. We are not liable for defects, outages, or damages arising from use of generated test content. By using this tool, you acknowledge that you are responsible for the outcome of any testing strategy that incorporates generated content.

4. PII Scrubbing
Prompts may be processed by an automated PII scrubber that detects and redacts: email addresses, phone numbers, URLs, IP addresses, credit card numbers, API keys, JWTs, and UUIDs. This is a best-effort mechanism and does not guarantee complete removal of all sensitive data. Do not include real credentials, personal data, or production secrets in prompts.

5. Fallback Processing
If the primary generation service is unavailable or returns invalid results, the app may fall back to local deterministic generation. These generated cases are simpler and rule-based, not derived from inference models.

6. Your Responsibility
By using this tool, you acknowledge that you are solely responsible for the quality and suitability of any testing strategy that incorporates generated content. We strongly recommend that all generated content is subjected to rigorous manual review and validation before being utilized in critical software development life cycles, testing environments, or production systems.''';

  static const String adsPolicy = '''
Ads & Monetization Policy
Last updated: June 22, 2026

QA Genie operates on a freemium model to ensure our generation services remain sustainable. Some features require watching a rewarded advertisement.

1. Rewarded Ads (Opt-In)
CORE tier users may unlock additional generation and export capacity by watching rewarded video ads delivered through the Google AdMob network.
- Ads are user-initiated only — you choose when to watch an ad
- A transaction token is generated upon ad completion and sent to our backend for verification
- Ad completion is verified server-side using a cryptographically random transaction token
- Attempting to spoof ad completion or bypass ad requirements violates our Terms of Service and may result in account suspension

2. Data & AdMob
By watching a rewarded ad, Google AdMob may collect:
- Advertising ID (Android Advertising ID)
- Device information
- IP address
- App interaction data
These identifiers are processed per Google's AdMob Privacy & Terms. You can opt out of ad personalization via Android Settings → Google → Ads → Opt out of Ads Personalization.

3. Ad-Free Pro Tier
PRO tier users experience no ads and bypass all ad-supported limitations. PRO status is managed via internal subscription verification logic. If you believe your PRO status is not correctly applied, please contact us through the app's Support → Report an Issue.

4. No Intrusive Ads
We do not serve interstitial, banner, or native ads during your workflow. The only ad format is rewarded video, triggered only by your explicit action:
- No pop-ups
- No auto-playing ads
- No background ad loading
- No interruption of your core workflow

5. Ad Integrity
Ad completion is verified server-side using a cryptographically random transaction token. Attempting to spoof ad completion or bypass ad requirements violates our Terms of Service and may result in account suspension.

6. Mediated Networks
In addition to AdMob, ads may be served through Unity Ads as a mediated partner. Each network operates under its own privacy policy and data handling practices.

7. Contact
General enquiries: hello@qagenies.com
Creator: chenchuenay@qagenies.com
Account deletion: wipe@qagenies.com (no take backs)''';
}
