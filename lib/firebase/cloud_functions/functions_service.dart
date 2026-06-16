import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';
import 'package:qa_genie/firebase/app_check/app_check_service.dart';

class FunctionsService {
  const FunctionsService();

  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  static Map<String, dynamic> normalizeResponseData(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>((key, entryValue) {
        return MapEntry(key.toString(), _normalizeResponseValue(entryValue));
      });
    }

    throw const FormatException('Cloud function response must be a map.');
  }

  static dynamic _normalizeResponseValue(dynamic value) {
    if (value is Map) {
      return normalizeResponseData(value);
    }

    if (value is List) {
      return value.map(_normalizeResponseValue).toList(growable: false);
    }

    return value;
  }

  static Future<Map<String, dynamic>> call({
    required String functionName,
    Map<String, dynamic>? payload,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    debugPrint('📡 FUNCTIONS_SERVICE [DIAGNOSTIC_V3]: Calling $functionName');
    
    // 🛡️ DIAGNOSTIC: Check App Check state (with timeout to prevent hanging)
    try {
      debugPrint('🛡️ FUNCTIONS_SERVICE [DIAGNOSTIC_V3]: Requesting AppCheck Token...');
      final appCheckToken = await AppCheckService.getToken().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('🛡️ FUNCTIONS_SERVICE: AppCheck Token request TIMEOUT');
          return null;
        },
      );
      debugPrint('🛡️ FUNCTIONS_SERVICE: AppCheck Token present: ${appCheckToken != null && appCheckToken.isNotEmpty}');
    } catch (e) {
      debugPrint('🛡️ FUNCTIONS_SERVICE: AppCheck diagnostic error: $e');
    }

    if (payload != null) {
      debugPrint('📦 FUNCTIONS_SERVICE: Payload keys: ${payload.keys.toList()}');
    }

    final startTime = DateTime.now();

    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );

      final result = await callable.call(payload ?? {});
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint(
        '✅ FUNCTIONS_SERVICE: $functionName succeeded (${latencyMs}ms)',
      );

      if (result.data == null) {
        throw Exception('Cloud function returned null.');
      }

      final data = normalizeResponseData(result.data);
      data['_metadata'] = {
        'functionName': functionName,
        'latencyMs': latencyMs,
        'timestamp': DateTime.now().toIso8601String(),
      };
      return data;
    } on FirebaseFunctionsException catch (e) {
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      ErrorCaptureUtils.logError(
        source: 'FunctionsService.$functionName',
        error: e,
        additionalInfo:
            'Code: ${e.code}, Message: ${e.message}, Details: ${e.details}',
      );
      return {
        'success': false,
        'error': {
          'code': e.code,
          'message': e.message ?? 'Cloud function error',
          'details': e.details,
        },
        '_metadata': {
          'functionName': functionName,
          'latencyMs': latencyMs,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    } catch (e) {
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      ErrorCaptureUtils.logError(
        source: 'FunctionsService.$functionName',
        error: e,
      );
      return {
        'success': false,
        'error': {'code': 'CLIENT_ERROR', 'message': e.toString()},
        '_metadata': {
          'functionName': functionName,
          'latencyMs': latencyMs,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };
    }
  }

  static Future<Map<String, dynamic>> getQuotaStatus() async {
    return call(functionName: 'getQuotaStatus');
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    return call(functionName: 'getUserDashboard', payload: {'type': 'user'});
  }

  static Future<void> trackGenerationUsage() async {
    // Redundant as 'generate' now tracks usage server-side, but keep for manual fallbacks
    await call(functionName: 'trackGeneration');
  }

  static Future<bool> verifyReward({required String rewardToken}) async {
    // Note: Reusing trackExport with token for now or we can add a specific verifier
    final result = await call(
      functionName: 'trackExport',
      payload: {'adToken': rewardToken, 'exportType': 'reward_verification'},
    );
    return result['success'] == true;
  }

  static Future<bool> healthCheck() async {
    try {
      final result = await call(functionName: 'healthCheck');
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String generateAdToken() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }

  static Future<void> trackGeneration(int generatedCount) async {
    await call(
      functionName: 'trackGeneration',
      payload: {'generatedCount': generatedCount},
    );
  }

  static Future<void> trackExport({
    required bool summary,
    required String target,
    required String extension,
  }) async {
    await call(
      functionName: 'trackExport',
      payload: {'summary': summary, 'target': target, 'extension': extension},
    );
  }

  static Future<void> trackProInterest(String source) async {
    await call(functionName: 'trackProInterest', payload: {'source': source});
  }

  static Future<void> trackAiFailure() async {
    await call(functionName: 'trackAiFailure', payload: {});
  }

  static Future<void> trackValidatorRejected(int rejectedCount) async {
    await call(
      functionName: 'trackValidatorRejected',
      payload: {'rejectedCount': rejectedCount},
    );
  }

  static Future<String> getGuestToken({required String deviceId}) async {
    final result = await call(
      functionName: 'getOrCreateGuestToken',
      payload: {'deviceId': deviceId},
    );
    // Check for success flag or presence of token
    if (result.containsKey('token') && result['token'] is String) {
      return result['token'] as String;
    }
    // Log the full error and throw
    final error =
        result['error'] ?? {'code': 'UNKNOWN', 'message': 'No token returned'};
    throw Exception(
      'Failed to get guest token: ${error['code']} - ${error['message']}',
    );
  }

  static Future<bool> verifyRewardAd({required String adTransactionId}) async {
    final result = await call(
      functionName: 'verifyRewardAd',
      payload: {'adTransactionId': adTransactionId},
    );
    return result['verified'] == true;
  }

  static Future<void> linkGoogleAccount({
    required String email,
    required String displayName,
    required String deviceId,
  }) async {
    await call(
      functionName: 'linkGoogleAccount',
      payload: {
        'email': email,
        'displayName': displayName,
        'deviceId': deviceId,
      },
    );
  }
}
