import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// lib/features/beta/logic/beta_manager.dart

class BetaManager {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _installTimeKey = 'beta_install_epoch';

  static const String _lastSeenKey = 'beta_last_seen';

  static const String _launchCountKey = 'beta_launch_count';

  static const String _lastBuildKey = 'beta_last_build';

  static const String _tamperKey = 'beta_clock_tamper';

  static const String _expiryKey = 'beta_expiry_epoch';

  static const int _betaDays = 45;

  static Future<void> recordInstallIfNew() async {
    final existing = await _storage.read(key: _installTimeKey);

    if (existing != null) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    await _storage.write(key: _installTimeKey, value: now.toString());

    final expiry = DateTime.now()
        .add(const Duration(days: _betaDays))
        .millisecondsSinceEpoch;

    await _storage.write(key: _expiryKey, value: expiry.toString());
  }

  static Future<void> touch() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;

      final lastSeenRaw = await _storage.read(key: _lastSeenKey);

      if (lastSeenRaw != null) {
        final lastSeen = int.tryParse(lastSeenRaw) ?? 0;

        if (now < lastSeen) {
          await _storage.write(key: _tamperKey, value: 'true');
        }
      }

      await _storage.write(key: _lastSeenKey, value: now.toString());

      final currentLaunches =
          int.tryParse(await _storage.read(key: _launchCountKey) ?? '0') ?? 0;

      await _storage.write(
        key: _launchCountKey,
        value: (currentLaunches + 1).toString(),
      );

      final package = await PackageInfo.fromPlatform();

      await _storage.write(
        key: _lastBuildKey,
        value: '${package.version}+${package.buildNumber}',
      );
    } catch (e) {
      debugPrint('Beta touch failed: $e');
    }
  }

  static Future<bool> isExpired() async {
    try {
      final raw = await _storage.read(key: _expiryKey);

      if (raw == null) {
        return false;
      }

      final expiry = int.tryParse(raw) ?? 0;

      return DateTime.now().millisecondsSinceEpoch > expiry;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isUpdateRequired() async {
    try {
      final package = await PackageInfo.fromPlatform();

      final build = int.tryParse(package.buildNumber) ?? 0;

      return build < 1;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> hasClockTamper() async {
    return (await _storage.read(key: _tamperKey)) == 'true';
  }

  static Future<Map<String, dynamic>> diagnostics() async {
    final package = await PackageInfo.fromPlatform();

    return {
      'version': package.version,
      'build': package.buildNumber,
      'launches': await _storage.read(key: _launchCountKey) ?? '0',
      'tamper': await hasClockTamper(),
      'expired': await isExpired(),
    };
  }

  static Future<String> diagnosticsJson() async {
    final data = await diagnostics();

    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
