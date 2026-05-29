// ============================================================
// FILE: lib/core/config/app_environment.dart
// ============================================================

/// ===============================================================
///
/// QA GENIE ENVIRONMENT AUTHORITY
///
/// SINGLE SOURCE OF TRUTH
///
/// ONLY TWO MODES EXIST:
///
/// 1. DEV
///    - Internal testing
///    - Mock authority
///    - Local rewards
///    - Debug tools
///    - Fast iteration
///
/// 2. PROD
///    - App Check enforced
///    - Cloud authority enforced
///    - Server-side quotas
///    - Abuse prevention
///    - Production monetization
///
/// IMPORTANT:
/// NO STAGING
/// NO HYBRID
/// NO PARTIAL SECURITY
///
/// ===============================================================
library;

enum AppEnvironment { dev, prod }

/// ===============================================================
///
/// ENVIRONMENT AUTHORITY
///
/// COMPILE-TIME CONTROLLED.
///
/// Example:
///
/// DEV:
/// flutter run
///
/// PROD:
/// flutter build appbundle --dart-define=MODE=prod
///
/// ===============================================================
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

  static bool get allowOfflineGeneration => isDev;

  static bool get requireCloudAuthority => isProd;

  static bool get requireAppCheck => isProd;

  static bool get requireSignedTokens => isProd;

  static bool get requirePiiScrubbing => isProd;

  static bool get requireForensicTracing => isProd;

  static bool get enforceServerQuota => isProd;

  // ============================================================
  // RATE LIMITING
  // ============================================================

  static Duration get minimumGenerationCooldown {
    if (isProd) {
      return const Duration(seconds: 30);
    }

    return const Duration(seconds: 1);
  }

  // ============================================================
  // LOGGING
  // ============================================================

  static int get forensicLogRetentionDays {
    if (isProd) {
      return 30;
    }

    return 3;
  }

  // ============================================================
  // TOKEN LIMITS
  // ============================================================

  static int get maxPromptCharacters {
    if (isProd) {
      return 12000;
    }

    return 20000;
  }

  static int get maxConstraintsLength => 100;

  // ============================================================
  // EXPORT SAFETY
  // ============================================================

  static bool get strictExportValidation => isProd;

  // ============================================================
  // DISPLAY
  // ============================================================

  static String get displayName {
    switch (current) {
      case AppEnvironment.dev:
        return 'DEV';

      case AppEnvironment.prod:
        return 'PROD';
    }
  }

  // ============================================================
  // BUILD SUMMARY
  // ============================================================

  static Map<String, dynamic> diagnostics() {
    return {
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
}
