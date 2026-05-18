class ValidatorTrace {
  final String testCaseId;
  final String title;
  final int qualityScore;
  final List<String> failedRules;
  final String? missingFields;
  final bool genericDetection;
  final double? duplicateSimilarity;

  ValidatorTrace({
    required this.testCaseId,
    required this.title,
    required this.qualityScore,
    required this.failedRules,
    this.missingFields,
    required this.genericDetection,
    this.duplicateSimilarity,
  });
}

class RepairTrace {
  final DateTime timestamp;
  final String testCaseId;
  final String changedField;
  final String before;
  final String after;
  final String reason;
  final bool success;

  RepairTrace({
    required this.timestamp,
    required this.testCaseId,
    required this.changedField,
    required this.before,
    required this.after,
    required this.reason,
    required this.success,
  });
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

class ParserTrace {
  final bool parseSuccess;
  final int parsedCaseCount;
  final int malformedBlocks;
  final List<String> parserFailures;
  ParserTrace({required this.parseSuccess, required this.parsedCaseCount, required this.malformedBlocks, required this.parserFailures});
}

class PerformanceTrace {
  final int promptBuildMs;
  final int apiCallMs;
  final int parseMs;
  final int validationMs;
  final int repairMs;
  final int fallbackMs;
  final int totalMs;
  PerformanceTrace({required this.promptBuildMs, required this.apiCallMs, required this.parseMs, required this.validationMs, required this.repairMs, required this.fallbackMs, required this.totalMs});
}

class FallbackTrace {
  final bool triggered;
  final String triggerReason;
  final String fallbackSource;
  final int generatedCount;
  final int acceptedCount;
  final int rejectedCount;
  FallbackTrace({required this.triggered, required this.triggerReason, required this.fallbackSource, required this.generatedCount, required this.acceptedCount, required this.rejectedCount});
}

class DedupTrace {
  final int aiInputCount;
  final int duplicatesRemoved;
  final int fallbackGeneratedCount;
  final int finalOutputCount;
  
  const DedupTrace({
    required this.aiInputCount,
    required this.duplicatesRemoved,
    required this.fallbackGeneratedCount,
    required this.finalOutputCount,
  });
}

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
