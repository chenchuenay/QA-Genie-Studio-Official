// ============================================================
// FILE: lib/core/config/app_environment.dart
// ============================================================
//
// ☝️ SINGLE SOURCE OF TRUTH for dev vs prod environment.
//
// Example:
//   flutter run                      → dev (default)
//   flutter run  --dart-define=MODE=prod
//   flutter build appbundle --dart-define=MODE=prod
//
// ============================================================

library;

enum AppEnvironment { dev, prod }

class EnvironmentAuthority {
  const EnvironmentAuthority._();

  // ============================================================
  // COMPILE-TIME MODE
  // ============================================================

  static const String _mode = String.fromEnvironment(
    'MODE',
    defaultValue: 'dev',
  );

  // ============================================================
  // CURRENT ENVIRONMENT
  // ============================================================

  static const AppEnvironment current = _mode == 'prod'
      ? AppEnvironment.prod
      : AppEnvironment.dev;

  // ============================================================
  // HELPERS
  // ============================================================

  static bool get isDev => current == AppEnvironment.dev;

  static bool get isProd => current == AppEnvironment.prod;

  static bool get isProduction => isProd;

  // ============================================================
  // SECURITY RULES
  // ============================================================

  static bool get allowDebugLogs => isDev;

  static bool get allowVerboseErrors => isDev;

  static bool get allowMockAds => isDev;

  static bool get allowLocalQuotaReset => isDev;

  static bool get requireCloudAuthority => isProd;

  static bool get requireAppCheck => isProd;

  static bool get requireSignedTokens => isProd;

  static bool get requirePiiScrubbing => isProd;

  static bool get requireForensicTracing => isProd;

  static bool get enforceServerQuota => isProd;

  // ============================================================
  // RATE LIMITING
  // ============================================================

  static Duration get minimumGenerationCooldown =>
      isProd ? const Duration(seconds: 30) : const Duration(seconds: 1);

  // ============================================================
  // LOGGING
  // ============================================================

  static int get forensicLogRetentionDays => isProd ? 30 : 3;

  // ============================================================
  // TOKEN LIMITS
  // ============================================================

  static int get maxPromptCharacters => isProd ? 12000 : 20000;

  static int get maxConstraintsLength => 100;

  // ============================================================
  // EXPORT SAFETY
  // ============================================================

  static bool get strictExportValidation => isProd;

  // ============================================================
  // DISPLAY
  // ============================================================

  static String get displayName => isDev ? 'DEV' : 'PROD';

  // ============================================================
  // BUILD SUMMARY
  // ============================================================

  static Map<String, dynamic> diagnostics() => {
        'environment': displayName,
        'allowDebugLogs': allowDebugLogs,
        'allowMockAds': allowMockAds,
        'requireCloudAuthority': requireCloudAuthority,
        'requireAppCheck': requireAppCheck,
        'requireSignedTokens': requireSignedTokens,
        'requirePiiScrubbing': requirePiiScrubbing,
        'requireForensicTracing': requireForensicTracing,
        'strictExportValidation': strictExportValidation,
      };
}
