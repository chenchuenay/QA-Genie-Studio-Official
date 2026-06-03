import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
// ============================================================
// FILE: lib/firebase/cloud_functions/functions_service.dart
// ============================================================

/// ===============================================================
///
/// FUNCTIONS SERVICE
///
/// PURPOSE:
/// - Centralized Cloud Functions access layer
/// - Timeout standardization
/// - Error normalization
/// - Safer callable management
///
/// IMPORTANT:
/// ALL CLOUD FUNCTION CALLS SHOULD FLOW HERE.
///
/// ===============================================================
class FunctionsService {
  const FunctionsService();

  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ============================================================
  // GENERIC CALL
  // ============================================================

  static Future<Map<String, dynamic>> call({
    required String functionName,
    Map<String, dynamic>? payload,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    debugPrint('REACHED_FUNCTIONS_SERVICE');
    debugPrint('LOG_1: Entering FunctionsService.call');
    debugPrint('LOG_2: Function name called: $functionName');

    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );

      try {
        final result = await callable.call(payload ?? {});
        debugPrint('CALLABLE_SUCCESS');
        debugPrint('CALLABLE_DATA=${result.data}');

        debugPrint(
          'LOG_3: FunctionsService returned runtimeType: ${result.data.runtimeType}',
        );
        debugPrint(
          'LOG_4: FunctionsService returned full payload: ${result.data}',
        );
        if (result.data is Map) {
          debugPrint(
            'LOG_5: FunctionsService payload keys: ${(result.data as Map).keys}',
          );
        }

        if (result.data == null) {
          throw Exception('Cloud function returned null.');
        }

        return Map<String, dynamic>.from(result.data);
      } catch (e, st) {
        debugPrint('CALLABLE_EXCEPTION=$e');
        debugPrint('CALLABLE_STACK=$st');
        rethrow;
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('FIREBASE_FUNCTION_CODE=${e.code}');
      debugPrint('FIREBASE_FUNCTION_MESSAGE=${e.message}');
      debugPrint('FIREBASE_FUNCTION_DETAILS=${e.details}');
      throw Exception(_mapError(e));
    } catch (e) {
      rethrow;
    }
  }

  // ============================================================
  // AUTHORIZATION
  // ============================================================

  static Future<Map<String, dynamic>> authorizeGeneration({
    required String actionType,
  }) async {
    return call(
      functionName: 'authorizeGeneration',
      payload: {
        'actionType': actionType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  // ============================================================
  // QUOTA
  // ============================================================

  static Future<Map<String, dynamic>> getQuotaStatus() async {
    return call(functionName: 'getQuotaStatus');
  }

  // ============================================================
  // TRACK USAGE
  // ============================================================

  static Future<void> trackGeneration() async {
    await call(
      functionName: 'trackGenerationUsage',
      payload: {'timestamp': DateTime.now().millisecondsSinceEpoch},
    );
  }

  // ============================================================
  // REWARDED ADS
  // ============================================================

  static Future<bool> verifyReward({required String rewardToken}) async {
    final result = await call(
      functionName: 'verifyRewardedAd',
      payload: {'rewardToken': rewardToken},
    );

    return result['verified'] == true;
  }

  // ============================================================
  // HEALTH CHECK
  // ============================================================

  static Future<bool> healthCheck() async {
    try {
      final result = await call(functionName: 'healthCheck');

      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // ERROR MAP
  // ============================================================

  static String _mapError(FirebaseFunctionsException e) {
    switch (e.code) {
      case 'unauthenticated':
        return 'Authentication required.';

      case 'permission-denied':
        return 'Permission denied.';

      case 'resource-exhausted':
        return 'Quota exhausted.';

      case 'deadline-exceeded':
        return 'Request timeout.';

      case 'unavailable':
        return 'Cloud service unavailable.';

      case 'internal':
        return 'Internal cloud error.';

      default:
        return e.message ?? 'Cloud function failed.';
    }
  }
}
