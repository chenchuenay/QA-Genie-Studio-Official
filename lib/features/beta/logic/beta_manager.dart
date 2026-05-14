import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BetaManager {
  static const _storage = FlutterSecureStorage();
  static const _installTimeKey = 'beta_install_epoch';

  static Future<void> recordInstallIfNew() async {
    final existing = await _storage.read(key: _installTimeKey);
    if (existing == null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _storage.write(key: _installTimeKey, value: now.toString());
    }
  }

  static Future<bool> isExpired() async {
    return false; // beta check disabled for debugging
  }

  static Future<bool> isUpdateRequired() async => false;
  static Future<void> touch() async {}
}
