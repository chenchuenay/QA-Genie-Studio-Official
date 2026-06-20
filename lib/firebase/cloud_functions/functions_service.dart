import 'dart:async';
import 'dart:io';
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

  static const int _maxRetries = 1;
  static const List<Duration> _retryDelays = [
    Duration(seconds: 1),
  ];

  static bool _isRetriable(Object error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unavailable':
        case 'deadline-exceeded':
        case 'internal':
        case 'resource-exhausted':
          return true;
        default:
          return false;
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> _callOnce({
    required String functionName,
    Map<String, dynamic>? payload,
    Duration timeout = const Duration(seconds: 30),
    int attempt = 1,
  }) async {
    final startTime = DateTime.now();

    try {
      final callable = _functions.httpsCallable(
        functionName,
        options: HttpsCallableOptions(timeout: timeout),
      );

      final result = await callable.call(payload ?? {});
      final latencyMs = DateTime.now().difference(startTime).inMilliseconds;
      debugPrint(
        '✅ FUNCTIONS_SERVICE: $functionName succeeded (${latencyMs}ms) attempt #$attempt',
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
            'Attempt: $attempt, Code: ${e.code}, Message: ${e.message}, Details: ${e.details}',
      );

      if (attempt < _maxRetries && _isRetriable(e)) {
        final delay = _retryDelays[attempt - 1];
        debugPrint('🔄 FUNCTIONS_SERVICE: Retrying $functionName in ${delay.inSeconds}s (attempt #${attempt + 1})');
        await Future.delayed(delay);
        return _callOnce(
          functionName: functionName,
          payload: payload,
          timeout: timeout,
          attempt: attempt + 1,
        );
      }

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

      if (attempt < _maxRetries && _isRetriable(e)) {
        final delay = _retryDelays[attempt - 1];
        debugPrint('🔄 FUNCTIONS_SERVICE: Retrying $functionName in ${delay.inSeconds}s (attempt #${attempt + 1})');
        await Future.delayed(delay);
        return _callOnce(
          functionName: functionName,
          payload: payload,
          timeout: timeout,
          attempt: attempt + 1,
        );
      }

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

  static Future<Map<String, dynamic>> call({
    required String functionName,
    Map<String, dynamic>? payload,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    debugPrint('📡 FUNCTIONS_SERVICE: Calling $functionName');

    // Non-blocking AppCheck diagnostic — does not delay the actual call
    unawaited(AppCheckService.getToken().timeout(
      const Duration(seconds: 5),
      onTimeout: () => null,
    ).then((token) {
      debugPrint('🛡️ AppCheck token present: ${token != null && token.isNotEmpty}');
    }).catchError((e) {
      debugPrint('🛡️ AppCheck diagnostic error: $e');
    }));

    if (payload != null) {
      debugPrint('📦 FUNCTIONS_SERVICE: Payload keys: ${payload.keys.toList()}');
    }

    return _callOnce(
      functionName: functionName,
      payload: payload,
      timeout: timeout,
    );
  }

  static Future<Map<String, dynamic>> getUserStats() async {
    return call(functionName: 'getUserDashboard', payload: {'type': 'user'});
  }

  static Future<bool> verifyReward({required String rewardToken}) async {
    // Delegates to the dedicated verifyRewardAd cloud function
    return verifyRewardAd(adTransactionId: rewardToken);
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

  static Future<String> getGuestToken({required String deviceId, bool forceReturning = false}) async {
    final result = await call(
      functionName: 'getOrCreateGuestToken',
      payload: {'deviceId': deviceId, 'forceReturning': forceReturning},
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

  static Future<Map<String, dynamic>> submitIssueReport({
    String? type,
    String? title,
    String? description,
    String? steps,
  }) async {
    return call(
      functionName: 'submitIssueReport',
      payload: {
        'issueType': type ?? 'Bug',
        'title': title ?? '',
        'description': description ?? '',
        'steps': steps ?? '',
      },
    );
  }
}
