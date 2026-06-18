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

  // ============================================================
  // QUOTA CHECK
  // ============================================================

  Future<bool> canGenerate() async {
    try {
      final callable = _functions.httpsCallable('checkGenerationQuota');

      final response = await callable.call();

      final data = Map<String, dynamic>.from(response.data);

      return data['allowed'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // REWARDED ADS
  // ============================================================

  Future<bool> verifyRewardedAd({required String adTransactionId}) async {
    try {
      final callable = _functions.httpsCallable('verifyRewardAd');

      final response = await callable.call({'adTransactionId': adTransactionId});

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
      final callable = _functions.httpsCallable('checkGenerationQuota');

      final response = await callable.call();

      final data = Map<String, dynamic>.from(response.data);

      return data['remaining'] ?? 0;
    } catch (_) {
      return 0;
    }
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

}
