import 'package:firebase_installations/firebase_installations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtils {
  static const String _deviceIdKey = 'unique_device_identifier';

  static Future<String> getUniqueId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_deviceIdKey);

    if (id != null && id.isNotEmpty) {
      return id;
    }

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
}
