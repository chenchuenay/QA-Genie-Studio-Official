class PlatformRules {
  static const Map<String, List<String>> _forbiddenTerms = {
    'Web': [
      'jwt',
      'bearer token',
      'adb',
      'swipe',
      'swiping',
      'tap',
      'tapping',
      'long press',
      'pinch',
      'biometric',
      'fingerprint',
      'face id',
      'mobile permission',
      'push notification',
      'app background',
      'force-killed',
      'apk',
      'http response body',
    ],
    'Mobile': [
      'cookie',
      'browser refresh',
      'refresh the browser',
      'hover',
      'ctrl+f5',
      'ctrl + f5',
      'right click',
      'tab key',
      'browser tab',
    ],
    'API': [
      'click button',
      'navigate page',
      'tap screen',
      'press save',
      'press continue',
      'form filling',
      'page loads',
      'page renders',
      'screen opens',
      'screen renders',
      'dashboard',
      'toast',
      'modal',
    ],
  };

  static String slugifyFeature(String feature) {
    return feature
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  static String apiEndpoint(String feature) {
    return '/${slugifyFeature(feature)}';
  }

  static bool violatesPlatform(String platform, String text) {
    final normalized = text.toLowerCase();
    final forbidden = _forbiddenTerms[platform] ?? const <String>[];
    if (forbidden.any(normalized.contains)) return true;

    switch (platform) {
      case 'Web':
        return RegExp(
          r'\b(adb|apk|swip\w*|tap\w*|pinch\w*|biometric|fingerprint|face id|push notification|device permission)\b',
        ).hasMatch(normalized);
      case 'Mobile':
        return RegExp(
          r'\b(hover\w*|right[- ]click|ctrl\s*\+?\s*f5|browser refresh|browser tab|cookie tamper\w*)\b',
        ).hasMatch(normalized);
      case 'API':
        return RegExp(
          r'\b(click button|click on|tap screen|tap on|press save|press continue|navigate page|navigate to page|open dashboard|page loads|screen opens|modal appears|toast appears|fill (the )?form)\b',
        ).hasMatch(normalized);
      default:
        return false;
    }
  }
}
