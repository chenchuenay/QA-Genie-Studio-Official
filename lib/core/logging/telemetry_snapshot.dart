import 'error_registry.dart';
import 'telemetry_models.dart';

class TelemetrySnapshot {
  final String sessionId;
  final DateTime timestamp;
  final String provider;
  final String model;
  final String mode;
  final String generationState;

  // Header & System metadata
  final bool forensicMode;
  final String buildMode;
  final String appVersion;
  final String buildNumber;
  final String os;
  final String osVersion;
  final String device;
  final String locale;
  final String timezone;
  final String flutterVersion;
  final String dartVersion;

  // User Input
  final String module;
  final String feature;
  final String platform;
  final String constraints;
  final int requestedCount;

  // Pipeline Data
  final String prompt;
  final String rawResponse;
  final int promptTokensEstimate;
  final int responseTokensEstimate;
  final bool sessionCompleted;

  // Pipeline Metrics
  final int repairedCases;
  final int fallbackGeneratedCases;
  final String fallbackReason;
  final DedupTrace? dedupTrace;

  final String integrityHash;
  final int totalDurationMs;
  final List<String> stateTransitions;
  final List<dynamic> finalCasesJson;

  final List<ValidatorTrace> validatorTraces;
  final List<RepairTrace> repairTraces;
  final List<ExportTrace> exportTraces;
  final List<UiErrorTrace> uiErrorTraces;

  final ParserTrace? parserTrace;
  final PerformanceTrace? performanceTrace;
  final NetworkTrace? networkTrace;
  final FallbackTrace? fallbackTrace;

  final ErrorRegistry errorRegistry;

  const TelemetrySnapshot({
    required this.sessionId,
    required this.timestamp,
    required this.provider,
    required this.model,
    required this.mode,
    required this.generationState,
    required this.forensicMode,
    required this.buildMode,
    required this.appVersion,
    required this.buildNumber,
    required this.os,
    required this.osVersion,
    required this.device,
    required this.locale,
    required this.timezone,
    required this.flutterVersion,
    required this.dartVersion,
    required this.module,
    required this.feature,
    required this.platform,
    required this.constraints,
    required this.requestedCount,
    required this.prompt,
    required this.rawResponse,
    required this.promptTokensEstimate,
    required this.responseTokensEstimate,
    required this.sessionCompleted,
    required this.repairedCases,
    required this.fallbackGeneratedCases,
    required this.fallbackReason,
    this.dedupTrace,
    required this.integrityHash,
    required this.totalDurationMs,
    required this.stateTransitions,
    required this.finalCasesJson,
    required this.validatorTraces,
    required this.repairTraces,
    required this.exportTraces,
    required this.uiErrorTraces,
    required this.parserTrace,
    required this.performanceTrace,
    required this.networkTrace,
    required this.fallbackTrace,
    required this.errorRegistry,
  });
}
