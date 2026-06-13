import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceUtils {
  static const String _deviceIdKey = 'unique_device_identifier';

  static Future<String> getUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);

    if (id != null && id.isNotEmpty) {
      return id;
    }

    // Generate a persistent hardware-linked ID
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        id = androidInfo.id; // Usually consistent across reinstalls
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        id = iosInfo.identifierForVendor;
      }
    } catch (_) {
      // Fallback to random UUID if hardware ID fails
      id = const Uuid().v4();
    }

    if (id == null || id.isEmpty) {
      id = const Uuid().v4();
    }

    await prefs.setString(_deviceIdKey, id);
    return id;
  }
}
