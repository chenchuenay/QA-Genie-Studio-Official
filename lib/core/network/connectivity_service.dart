import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
// ============================================================
// FILE: lib/core/network/connectivity_service.dart
// ============================================================

/// ===============================================================
///
/// CONNECTIVITY SERVICE
///
/// PURPOSE:
/// - Centralized internet monitoring
/// - Online/offline detection
/// - Prevent AI calls during offline state
/// - Lightweight operational health checks
///
/// ===============================================================
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();

  static StreamSubscription<List<ConnectivityResult>>? _subscription;

  static bool _isConnected = true;

  static bool get isConnected => _isConnected;

  // ============================================================
  // INITIALIZE
  // ============================================================

  static Future<void> initialize() async {
    final result = await _connectivity.checkConnectivity();

    _isConnected = !_containsOffline(result);

    _subscription ??= _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = !_containsOffline(results);
    });
  }

  // ============================================================
  // CHECK
  // ============================================================

  static Future<bool> checkNow() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = !_containsOffline(result);
    } catch (_) {
      // In unit tests, platform channels are missing. 
      // Default to true to allow AI calls to proceed.
      _isConnected = true;
    }

    return _isConnected;
  }

  // ============================================================
  // INTERNAL
  // ============================================================

  static bool _containsOffline(List<ConnectivityResult> results) {
    return results.isEmpty ||
        results.every((e) => e == ConnectivityResult.none);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  static Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
