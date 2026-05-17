import 'telemetry_models.dart';
import 'telemetry_snapshot.dart';

class TelemetryCollector {
  static final TelemetryCollector _instance = TelemetryCollector._internal();
  factory TelemetryCollector() => _instance;
  TelemetryCollector._internal();

  final List<ValidatorTrace> _validatorTraces = [];
  final List<RepairTrace> _repairTraces = [];
  final List<ExportTrace> _exportTraces = [];
  final List<UiErrorTrace> _uiErrorTraces = [];
  NetworkTrace? _networkTrace;

  // Session metadata
  String _sessionMode = '';
  String _provider = '';
  String _model = '';
  int _timeoutMs = 0;
  int _retryCount = 0;
  int _promptChars = 0;
  int _requestedCount = 0;
  
  // Timings
  int _promptBuildMs = 0;
  int _apiCallMs = 0;
  int _parseMs = 0;
  int _validationMs = 0;
  int _repairMs = 0;
  int _totalMs = 0;

  void startSession(String mode, String provider, String model) {
    _sessionMode = mode;
    _provider = provider;
    _model = model;
  }

  void endSession(bool success, int durationMs) {
    // Not used in minimal Phase 1
  }

  void recordNetworkTrace(NetworkTrace trace) { _networkTrace = trace; }
  void recordValidatorTrace(ValidatorTrace trace) { _validatorTraces.add(trace); }
  void recordRepairTrace(RepairTrace trace) { _repairTraces.add(trace); }
  void recordExportTrace(ExportTrace trace) { _exportTraces.add(trace); }
  void recordUiErrorTrace(UiErrorTrace trace) { _uiErrorTraces.add(trace); }

  void setSessionMetadata({
    required String mode,
    required String provider,
    required String model,
    required int timeoutMs,
    required int retryCount,
    required int promptChars,
    required int requestedCount,
  }) {
    _sessionMode = mode;
    _provider = provider;
    _model = model;
    _timeoutMs = timeoutMs;
    _retryCount = retryCount;
    _promptChars = promptChars;
    _requestedCount = requestedCount;
  }

  void recordTiming(String stage, int ms) {
    switch (stage) {
      case 'prompt_build': _promptBuildMs = ms; break;
      case 'api_call': _apiCallMs = ms; break;
      case 'parse': _parseMs = ms; break;
      case 'validation': _validationMs = ms; break;
      case 'repair': _repairMs = ms; break;
      case 'total': _totalMs = ms; break;
    }
  }

  TelemetrySnapshot freeze() {
    return TelemetrySnapshot(
      validatorTraces: List.unmodifiable(_validatorTraces),
      repairTraces: List.unmodifiable(_repairTraces),
      exportTraces: List.unmodifiable(_exportTraces),
      uiErrorTraces: List.unmodifiable(_uiErrorTraces),
      networkTrace: _networkTrace,
      sessionMode: _sessionMode,
      provider: _provider,
      model: _model,
      timeoutMs: _timeoutMs,
      retryCount: _retryCount,
      promptChars: _promptChars,
      requestedCount: _requestedCount,
      promptBuildMs: _promptBuildMs,
      apiCallMs: _apiCallMs,
      parseMs: _parseMs,
      validationMs: _validationMs,
      repairMs: _repairMs,
      totalMs: _totalMs,
    );
  }

  void clear() {
    _validatorTraces.clear();
    _repairTraces.clear();
    _exportTraces.clear();
    _uiErrorTraces.clear();
    _networkTrace = null;
    _sessionMode = '';
    _provider = '';
    _model = '';
    _timeoutMs = 0;
    _retryCount = 0;
    _promptChars = 0;
    _requestedCount = 0;
    _promptBuildMs = 0;
    _apiCallMs = 0;
    _parseMs = 0;
    _validationMs = 0;
    _repairMs = 0;
    _totalMs = 0;
  }
}
