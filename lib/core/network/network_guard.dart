import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qa_genie/app/config/app_config.dart';
import 'package:qa_genie/core/ui/network_ui_helper.dart';

class NetworkGuard {
  static bool _isOnline = false;
  static bool get isOnline => _isOnline;
  static final ValueNotifier<bool> onlineStatus = ValueNotifier(false);
  static Timer? _debounceTimer;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static bool _httpCached = false;
  static DateTime? _lastHttpCheck;

  static Future<void> initialize() async {
    final connectivity = Connectivity();

    // Initial check
    final result = await connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);
    onlineStatus.value = _isOnline;

    // Listen for changes with debounce
    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final newState = !results.contains(ConnectivityResult.none);
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (_isOnline != newState) {
          _isOnline = newState;
          onlineStatus.value = newState;
          _httpCached = false;
          _lastHttpCheck = null;
          debugPrint('🌐 NetworkGuard: Connectivity changed to $_isOnline, HTTP cache cleared');
        }
      });
    });
  }

  static void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  static final List<String> _checkUrls = [
    'https://clients3.google.com/generate_204',
    'https://www.google.com/generate_204',
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://firebase.googleapis.com',
  ];

  static Future<bool> hasInternet() async {
    if (_httpCached && _lastHttpCheck != null) {
      final age = DateTime.now().difference(_lastHttpCheck!);
      if (age.inSeconds < 30) return true;
    }
    for (final url in _checkUrls) {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 5);
      try {
        final request = await client.headUrl(Uri.parse(url));
        final response = await request.close();
        if (response.statusCode == 204 || response.statusCode == 200) {
          _httpCached = true;
          _lastHttpCheck = DateTime.now();
          return true;
        }
      } catch (_) {
        continue;
      } finally {
        client.close(force: true);
      }
    }
    _httpCached = false;
    return false;
  }

  static Future<void> requireInternet() async {
    if (!await hasInternet()) throw Exception('No internet connection');
  }

  static Future<bool> ensureProductionOnline(BuildContext context) async {
    return await NetworkUiHelper.ensureProductionOnline(context);
  }

  static bool get isProduction => AppConfig.isProduction;
}

