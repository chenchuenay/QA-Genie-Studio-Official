import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/core/network/providers/api_client.dart';

class NetworkTraceStore {
  static int lastStatusCode = 0;
  static int lastDurationMs = 0;
  static String? lastErrorMessage;

  static void clear() {
    lastStatusCode = 0;
    lastDurationMs = 0;
    lastErrorMessage = null;
  }
}

class GenerationApi {
  final ApiClient _client;

  GenerationApi(this._client);

  Future<List<TestCaseModel>> generate(String prompt) async {
    final stopwatch = Stopwatch()..start();

    int statusCode = 0;
    String? errorMessage;

    try {
      NetworkTraceStore.clear();

      final cases = await _client.generate(prompt);

      statusCode = 200;

      return cases;
    } catch (e) {
      errorMessage = e.toString();

      if (errorMessage.contains('401')) {
        statusCode = 401;
      } else if (errorMessage.contains('403')) {
        statusCode = 403;
      } else if (errorMessage.contains('404')) {
        statusCode = 404;
      } else if (errorMessage.contains('429')) {
        statusCode = 429;
      } else if (errorMessage.contains('500')) {
        statusCode = 500;
      } else {
        statusCode = 0;
      }

      rethrow;
    } finally {
      stopwatch.stop();

      NetworkTraceStore.lastStatusCode = statusCode;
      NetworkTraceStore.lastDurationMs = stopwatch.elapsedMilliseconds;
      NetworkTraceStore.lastErrorMessage = errorMessage;
    }
  }
}
