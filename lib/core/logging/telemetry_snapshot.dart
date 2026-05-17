import 'telemetry_models.dart';

class TelemetrySnapshot {
  final List<ValidatorTrace> validatorTraces;
  final List<RepairTrace> repairTraces;
  final List<ExportTrace> exportTraces;
  final List<UiErrorTrace> uiErrorTraces;
  final NetworkTrace? networkTrace;
  final String sessionMode;
  final String provider;
  final String model;
  final int timeoutMs;
  final int retryCount;
  final int promptChars;
  final int requestedCount;
  final int promptBuildMs;
  final int apiCallMs;
  final int parseMs;
  final int validationMs;
  final int repairMs;
  final int totalMs;

  TelemetrySnapshot({
    required this.validatorTraces,
    required this.repairTraces,
    required this.exportTraces,
    required this.uiErrorTraces,
    this.networkTrace,
    required this.sessionMode,
    required this.provider,
    required this.model,
    required this.timeoutMs,
    required this.retryCount,
    required this.promptChars,
    required this.requestedCount,
    required this.promptBuildMs,
    required this.apiCallMs,
    required this.parseMs,
    required this.validationMs,
    required this.repairMs,
    required this.totalMs,
  });
}
