class IdGenerator {
  /// Returns a deterministic, readable business ID like TC_LOGIN_USER_001
  static String generate(String module, String feature, int index) {
    final mod = module.trim().split(RegExp(r'\s+')).first.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    final feat = feature.trim().split(RegExp(r'\s+')).first.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return 'TC_${mod}_${feat}_${index.toString().padLeft(3, '0')}';
  }
}
