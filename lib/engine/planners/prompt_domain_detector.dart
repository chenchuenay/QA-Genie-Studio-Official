class PromptDomainType {
  static const String emailAuth = 'emailAuth';
  static const String oauthSocial = 'oauthSocial';
  static const String apiKey = 'apiKey';
  static const String samlSso = 'samlSso';
  static const String generic = 'general';
}

class PromptDomainDetector {
  static String detect({required String feature, String constraints = ''}) {
    final text = '$feature $constraints'.toLowerCase();

    if (_matchesAny(text, [
      'saml', 'enterprise sso', 'active directory', 'ldap',
    ])) {
      return PromptDomainType.samlSso;
    }

    if (_matchesAny(text, [
      'api key', 'api token', 'bearer token', 'authorization header',
      'auth header', 'api auth',
    ])) {
      return PromptDomainType.apiKey;
    }

    if (_matchesAny(text, [
      'oauth',
      'social login',
      'sign in with google',
      'sign in with facebook',
      'login with google',
      'login with facebook',
      'google login',
      'facebook login',
    ])) {
      return PromptDomainType.oauthSocial;
    }

    if (_matchesAny(text, [
      'email', 'password', 'username', 'credentials',
    ])) {
      return PromptDomainType.emailAuth;
    }

    return PromptDomainType.generic;
  }

  static bool _matchesAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }
}
