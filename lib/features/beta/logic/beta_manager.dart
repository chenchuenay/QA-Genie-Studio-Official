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
    final stored = await _storage.read(key: _installTimeKey);
    if (stored == null) return false;
    final installMillis = int.tryParse(stored);
    if (installMillis == null) return false;
    final nowMillis = DateTime.now().millisecondsSinceEpoch;
    final elapsedSeconds = (nowMillis - installMillis) ~/ 1000;
    // 3 days = 259200 seconds
    return elapsedSeconds >= 259200;
  }

  static Future<bool> isUpdateRequired() async => false;
  static Future<void> touch() async {}
}
