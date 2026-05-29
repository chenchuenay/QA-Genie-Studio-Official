// ============================================================
// FILE: lib/core/utils/platform_utils.dart
// ============================================================

class PlatformUtils {
  const PlatformUtils._();

  // ==========================================================
  // NORMALIZATION
  // ==========================================================

  static String normalize(String value) {
    final v = value.trim().toLowerCase();

    switch (v) {
      case 'web':
      case 'website':
      case 'browser':
        return 'Web';

      case 'mobile':
      case 'android':
      case 'ios':
      case 'app':
        return 'Mobile';

      case 'api':
      case 'backend':
      case 'rest':
      case 'graphql':
        return 'API';

      default:
        return 'Web';
    }
  }

  // ==========================================================
  // CHECKERS
  // ==========================================================

  static bool isWeb(String value) {
    return normalize(value) == 'Web';
  }

  static bool isMobile(String value) {
    return normalize(value) == 'Mobile';
  }

  static bool isApi(String value) {
    return normalize(value) == 'API';
  }

  // ==========================================================
  // API ENDPOINT GENERATOR
  // ==========================================================

  static String apiEndpoint(String feature) {
    final cleaned = feature
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');

    return '/api/v1/$cleaned';
  }

  // ==========================================================
  // DISPLAY PREFIX
  // ==========================================================

  static String displayPrefix(String platform) {
    switch (normalize(platform)) {
      case 'API':
        return '[API]';

      case 'Mobile':
        return '[MOBILE]';

      default:
        return '[WEB]';
    }
  }
}
