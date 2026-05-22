import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:qa_genie/app/config/app_config.dart';

class UsageManager {
  static const _countKey = "daily_gen_count";
  static const _exportKey = "daily_export_count";
  static const _dateKey = "last_reset_date";
  static const _installIdKey = "install_id";
  static const _storage = FlutterSecureStorage();

  static Future<String> _getInstallationId() async {
    String? id = await _storage.read(key: _installIdKey);
    if (id == null) {
      final deviceInfo = DeviceInfoPlugin();
      final packageInfo = await PackageInfo.fromPlatform();
      final androidId = (await deviceInfo.androidInfo).id;
      final fp =
          "${packageInfo.packageName}_${androidId}_${DateTime.now().millisecondsSinceEpoch}";
      id = _hashString(fp);
      await _storage.write(key: _installIdKey, value: id);
      final prefs = await SharedPreferences.getInstance();
      if (!prefs.containsKey('first_launch_date')) {
        await prefs.setString(
          'first_launch_date',
          DateTime.now().toIso8601String(),
        );
      }
    }
    return id;
  }

  static String _hashString(String s) {
    final bytes = utf8.encode(s);
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isPro() async {
    if (!AppConfig.isProduction) return AppConfig.testProMode;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_pro') ?? false;
  }

  static Future<void> setPro(bool v) async {
    if (!AppConfig.isProduction) AppConfig.testProMode = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_pro', v);
    await prefs.setBool('testProMode', v);
  }

  // Reset all daily limits (for testing)
  static Future<void> resetLimits() async {
    final iid = await _getInstallationId();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_countKey}_$iid', 0);
    await prefs.setInt('${_exportKey}_$iid', 0);
  }

  static Future<String> _dateSuffix() async {
    final iid = await _getInstallationId();
    return '${_dateKey}_$iid';
  }

  static Future<void> _resetIfNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final ds = await _dateSuffix();
    final last = prefs.getString(ds);
    final today = DateTime.now().toIso8601String().split("T").first;
    if (last != today) {
      final iid = await _getInstallationId();
      await prefs.setString(ds, today);
      await prefs.setInt('${_countKey}_$iid', 0);
      await prefs.setInt('${_exportKey}_$iid', 0);
    }
  }

  static Future<int> getGenerationCount() async {
    await _resetIfNewDay();
    final iid = await _getInstallationId();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_countKey}_$iid') ?? 0;
  }

  static Future<void> incrementGeneration() async {
    await _resetIfNewDay();
    final iid = await _getInstallationId();
    final prefs = await SharedPreferences.getInstance();
    final c = await getGenerationCount();
    await prefs.setInt('${_countKey}_$iid', c + 1);
  }

  static Future<int> getExportCount() async {
    await _resetIfNewDay();
    final iid = await _getInstallationId();
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('${_exportKey}_$iid') ?? 0;
  }

  static Future<void> incrementExport() async {
    await _resetIfNewDay();
    final iid = await _getInstallationId();
    final prefs = await SharedPreferences.getInstance();
    final c = await getExportCount();
    await prefs.setInt('${_exportKey}_$iid', c + 1);
  }

  static Future<bool> canGenerate({bool afterRewardedAd = false}) async {
    final pro = await UsageManager.isPro();
    if (!AppConfig.isProduction && pro) return true;
    final count = await getGenerationCount();
    if (pro) return count < 15;
    if (count < 1) return true;
    if (count < 6) return afterRewardedAd;
    return false;
  }

  static Future<int> freeGensRemaining() async {
    final count = await getGenerationCount();
    if (count >= 6) return 0;
    return 6 - count;
  }

  static Future<int> proGensRemaining() async {
    final count = await getGenerationCount();
    return (15 - count).clamp(0, 15);
  }

  static Future<int> maxCasesPerBatch() async {
    return (await isPro()) ? 16 : 8;
  }


  static Future<bool> canExport({bool afterRewardedAd = false}) async {
    final pro = await isPro();
    if (pro) return true;
    final count = await getExportCount();
    if (count == 0) return true;
    return afterRewardedAd;
  }
}
