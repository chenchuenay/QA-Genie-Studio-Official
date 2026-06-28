import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_installations/firebase_installations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtils {
  static const String _deviceIdKey = 'unique_device_identifier';
  static const String _guestEverCreatedKey = 'guest_ever_created';

  static Future<String> getUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);

    if (id != null && id.isNotEmpty) {
      return id;
    }

    // Use ANDROID_ID as base (survives data clear), fallback to FirebaseInstallations
    try {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      id = deviceInfo.id;
      if (id.isNotEmpty) {
        await prefs.setString(_deviceIdKey, id);
        return id;
      }
    } catch (_) {}

    try {
      id = await FirebaseInstallations.id;
    } catch (_) {
      id = '${DateTime.now().millisecondsSinceEpoch}';
    }

    if (id == null || id.isEmpty) {
      id = '${DateTime.now().millisecondsSinceEpoch}';
    }

    await prefs.setString(_deviceIdKey, id);
    return id;
  }

  /// Whether a first-time guest account was ever created on this device.
  static Future<bool> guestEverCreated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_guestEverCreatedKey) ?? false;
  }

  /// Mark that a first-time guest was created on this device.
  static Future<void> setGuestEverCreated() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_guestEverCreatedKey, true);
  }
}
