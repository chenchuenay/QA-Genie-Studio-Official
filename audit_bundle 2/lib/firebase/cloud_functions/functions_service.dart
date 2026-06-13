import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:qa_genie/engine/forensics/error_capture_utils.dart';

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
    debugPrint('📡 FUNCTIONS_SERVICE: Calling $functionName');
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
    final result = await call(functionName: 'getUserStats', payload: {});
    // Force cast to Map<String, dynamic>
    return Map<String, dynamic>.from(result as Map);
  }

  static Future<void> trackGenerationUsage() async {
    await call(functionName: 'trackGenerationUsage');
  }

  static Future<bool> verifyReward({required String rewardToken}) async {
    final result = await call(
      functionName: 'verifyRewardedAd',
      payload: {'rewardToken': rewardToken},
    );
    return result['verified'] == true;
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
}
