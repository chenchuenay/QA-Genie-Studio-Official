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
    bool throwOnError = false,
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
          throwOnError: throwOnError,
        );
      }

      if (throwOnError) rethrow;

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
          throwOnError: throwOnError,
        );
      }

      if (throwOnError) rethrow;

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
    bool throwOnError = false,
  }) async {
    debugPrint('📡 FUNCTIONS_SERVICE: Calling $functionName');

    if (payload != null) {
      debugPrint('📦 FUNCTIONS_SERVICE: Payload keys: ${payload.keys.toList()}');
    }

    return _callOnce(
      functionName: functionName,
      payload: payload,
      timeout: timeout,
      throwOnError: throwOnError,
    );
  }

  static Future<Map<String, dynamic>> getMemberStats() async {
    return call(functionName: 'getMemberDashboard', payload: {'type': 'member'});
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

  static Future<Map<String, dynamic>> getGuestToken({required String deviceId, bool forceReturning = false, String caller = 'unknown', String? androidId}) async {
    final result = await call(
      functionName: 'getOrCreateGuestToken',
      payload: {'deviceId': deviceId, 'forceReturning': forceReturning, 'caller': caller, 'androidId': androidId},
    );
    if (result.containsKey('token') && result['token'] is String) {
      return result;
    }
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
    String? previousGuestUid,
  }) async {
    await call(
      functionName: 'linkGoogleAccount',
      payload: {
        'email': email,
        'displayName': displayName,
        'deviceId': deviceId,
        if (previousGuestUid != null) 'previousGuestUid': previousGuestUid,
      },
    );
  }

  /// Push a suite to cloud. Returns full result map (includes serialNumber on success).
  /// `serialNumber` is optional — if omitted the server generates one atomically.
  static Future<Map<String, dynamic>> pushMemberSuite({
    String? serialNumber,
    required String date,
    required Map<String, dynamic> suiteData,
  }) async {
    final payload = <String, dynamic>{
      'date': date,
      'suiteData': suiteData,
    };
    if (serialNumber != null) payload['serialNumber'] = serialNumber;
    return call(
      functionName: 'pushMemberSuite',
      payload: payload,
    );
  }

  /// Get all suites from cloud. Returns list of suite maps.
  static Future<List<Map<String, dynamic>>> getMemberSuites() async {
    final result = await call(functionName: 'getMemberSuites');
    if (result['success'] != true) {
      debugPrint('⚠️ getMemberSuites: cloud function returned failure');
      return [];
    }
    final suites = result['suites'];
    if (suites is! List) return [];
    return suites.cast<Map<String, dynamic>>();
  }

  /// Delete a suite from cloud by its cloud_id ("date/serialNumber").
  static Future<bool> deleteMemberSuite(String cloudId) async {
    final result = await call(
      functionName: 'deleteMemberSuite',
      payload: {'suiteId': cloudId},
    );
    return result['success'] == true;
  }

  static Future<Map<String, dynamic>> checkSessionByEmail({
    required String email,
    required String deviceId,
  }) async {
    return call(
      functionName: 'checkSessionByEmail',
      payload: {'email': email, 'deviceId': deviceId},
    );
  }

  static Future<Map<String, dynamic>> registerSession({
    required String deviceId,
    required bool force,
  }) async {
    return call(
      functionName: 'registerSession',
      payload: {'deviceId': deviceId, 'force': force},
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
