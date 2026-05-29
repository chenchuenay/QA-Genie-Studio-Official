import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
// ============================================================
// FILE: lib/core/network/cloud_authority_service.dart
// ============================================================

/// ===============================================================
///
/// CLOUD AUTHORITY SERVICE
///
/// PURPOSE:
/// - Production authority enforcement
/// - Signed generation token acquisition
/// - Server quota verification
/// - Usage tracking
/// - Reward verification bridge
///
/// IMPORTANT:
/// CLIENT NEVER TALKS DIRECTLY TO AI PROVIDER.
///
/// FLOW:
///
/// App
///   ↓
/// Firebase App Check
///   ↓
/// Firebase Cloud Function
///   ↓
/// Server validation
///   ↓
/// AI Provider
///
/// ===============================================================
class CloudAuthorityService {
  static final CloudAuthorityService instance = CloudAuthorityService();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // CACHE
  // ============================================================

  String? _cachedToken;

  DateTime? _cachedTokenExpiry;

  // ============================================================
  // TOKEN ACQUISITION
  // ============================================================

  Future<String> requestGenerationToken({required String actionType}) async {
    try {
      // ========================================================
      // CACHE HIT
      // ========================================================

      if (_cachedToken != null &&
          _cachedTokenExpiry != null &&
          DateTime.now().isBefore(_cachedTokenExpiry!)) {
        return _cachedToken!;
      }

      // ========================================================
      // AUTH CHECK
      // ========================================================

      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated.');
      }

      // ========================================================
      // TOKEN REFRESH
      // ========================================================

      await user.getIdToken(true);

      // ========================================================
      // CLOUD FUNCTION
      // ========================================================

      final callable = _functions.httpsCallable(
        'authorizeGeneration',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 25)),
      );

      final response = await callable.call({
        'actionType': actionType,
        'platform': defaultTargetPlatform.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final data = Map<String, dynamic>.from(response.data);

      // ========================================================
      // SERVER VALIDATION
      // ========================================================

      final success = data['success'] == true;

      if (!success) {
        final reason = data['reason'] ?? 'Authorization rejected.';

        throw Exception(reason);
      }

      final token = (data['generationToken'] ?? '').toString().trim();

      if (token.isEmpty) {
        throw Exception('Server returned empty token.');
      }

      // ========================================================
      // CACHE TOKEN
      // ========================================================

      _cachedToken = token;

      _cachedTokenExpiry = DateTime.now().add(const Duration(minutes: 4));

      return token;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(_mapFirebaseError(e));
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // QUOTA CHECK
  // ============================================================

  Future<bool> canGenerate() async {
    try {
      final callable = _functions.httpsCallable('getQuotaStatus');

      final response = await callable.call();

      final data = Map<String, dynamic>.from(response.data);

      return data['allowed'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> validateQuota({required String type, required int limit}) async {
    try {
      final callable = _functions.httpsCallable('validateQuota');

      final response = await callable.call({
        'type': type,
        'limit': limit,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      final data = Map<String, dynamic>.from(response.data);

      return data['allowed'] == true;
    } catch (_) {
      return canGenerate();
    }
  }

  // ============================================================
  // TRACK USAGE
  // ============================================================

  Future<void> trackGeneration() async {
    try {
      final callable = _functions.httpsCallable('trackGenerationUsage');

      await callable.call({'timestamp': DateTime.now().millisecondsSinceEpoch});
    } catch (_) {
      // Silent fail intentionally.
      // Server already tracks authoritative usage.
    }
  }

  Future<void> trackUsage({required String type, int value = 1}) async {
    try {
      final callable = _functions.httpsCallable('trackUsage');

      await callable.call({
        'type': type,
        'value': value,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {
      if (type == 'generation') {
        await trackGeneration();
      }
    }
  }

  // ============================================================
  // REWARDED ADS
  // ============================================================

  Future<bool> verifyRewardedAd({required String rewardToken}) async {
    try {
      final callable = _functions.httpsCallable('verifyRewardedAd');

      final response = await callable.call({'rewardToken': rewardToken});

      final data = Map<String, dynamic>.from(response.data);

      return data['verified'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // FETCH REMAINING QUOTA
  // ============================================================

  Future<int> remainingQuota() async {
    try {
      final callable = _functions.httpsCallable('getQuotaStatus');

      final response = await callable.call();

      final data = Map<String, dynamic>.from(response.data);

      return data['remaining'] ?? 0;
    } catch (_) {
      return 0;
    }
  }

  // ============================================================
  // RESET CACHE
  // ============================================================

  void clearTokenCache() {
    _cachedToken = null;
    _cachedTokenExpiry = null;
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  Future<bool> ping() async {
    try {
      final callable = _functions.httpsCallable('healthCheck');

      final response = await callable.call();

      return response.data != null;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // FIREBASE ERROR MAP
  // ============================================================

  String _mapFirebaseError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Authentication required.';

      case 'permission-denied':
        return 'Permission denied.';

      case 'resource-exhausted':
        return 'Daily quota exhausted.';

      case 'unavailable':
        return 'Cloud service unavailable.';

      case 'deadline-exceeded':
        return 'Server timeout occurred.';

      case 'internal':
        return 'Internal server error.';

      default:
        return e.message ?? 'Cloud authorization failed.';
    }
  }

  // ============================================================
  // DEBUG EXPORT
  // ============================================================

  Map<String, dynamic> diagnostics() {
    return {
      'cachedToken': _cachedToken != null,
      'cacheValid':
          _cachedTokenExpiry != null &&
          DateTime.now().isBefore(_cachedTokenExpiry!),
      'tokenExpiry': _cachedTokenExpiry?.toIso8601String(),
    };
  }
}
