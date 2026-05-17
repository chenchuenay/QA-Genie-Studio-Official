// Flat telemetry DTOs (immutable)
class NetworkTrace {
  final int statusCode;
  final int durationMs;
  final bool internetAvailable;
  final bool socketError;
  final bool tlsError;
  final int retryCount;
  final String? errorMessage;
  NetworkTrace({required this.statusCode, required this.durationMs, required this.internetAvailable, required this.socketError, required this.tlsError, required this.retryCount, this.errorMessage});
}

class ValidatorTrace {
  final String testCaseId;
  final String title;
  final int qualityScore;
  final List<String> failedRules;
  final String? missingFields;
  final bool genericDetection;
  final double? duplicateSimilarity;
  ValidatorTrace({required this.testCaseId, required this.title, required this.qualityScore, required this.failedRules, this.missingFields, required this.genericDetection, this.duplicateSimilarity});
}

class RepairTrace {
  final String testCaseId;
  final String originalProblem;
  final String strategy;
  final List<String> changedFields;
  final String before;
  final String after;
  final bool success;
  RepairTrace({required this.testCaseId, required this.originalProblem, required this.strategy, required this.changedFields, required this.before, required this.after, required this.success});
}

class ExportTrace {
  final String type;
  final bool success;
  final int durationMs;
  final int fileSizeBytes;
  final int inputCount;
  final int outputCount;
  final bool shareSuccess;
  ExportTrace({required this.type, required this.success, required this.durationMs, required this.fileSizeBytes, required this.inputCount, required this.outputCount, required this.shareSuccess});
}

class UiErrorTrace {
  final DateTime timestamp;
  final String screen;
  final String userMessage;
  final String technicalError;
  final String? stackTrace;
  UiErrorTrace({required this.timestamp, required this.screen, required this.userMessage, required this.technicalError, this.stackTrace});
}
