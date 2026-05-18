import 'package:qa_genie/core/logging/telemetry_models.dart';
import 'package:qa_genie/core/logging/telemetry_collector.dart';

enum ErrorSeverity { info, warning, error, critical }

enum ErrorSource {
  generationUi,
  exportEngine,
  uiPreview,
  framework,
  platform,
  auth,
  storage,
  network,
  aiProvider,
  bugReportUi,
  unknown
}

enum ErrorStage {
  request,
  rawResponse,
  parse,
  repair,
  validation,
  export,
  uiRender,
  generation,
  aiCall,
  runtime,
  submit,
  unknown
}

class UiErrorRecord {
  final DateTime timestamp;
  final String operationId; // matches a generation batch
  final ErrorSource source;
  final String screen; // screen name if applicable
  final ErrorStage stage;
  final ErrorSeverity severity;
  final String userMessage;
  final String technicalError;
  final String? stackTrace;

  UiErrorRecord({
    required this.timestamp,
    required this.operationId,
    required this.source,
    required this.screen,
    required this.stage,
    required this.severity,
    required this.userMessage,
    required this.technicalError,
    this.stackTrace,
  });

  @override
  String toString() {
    final buf = StringBuffer();
    buf.writeln(
      '[$timestamp] OP: $operationId | SOURCE: ${source.name.toUpperCase()} | SCREEN: $screen | STAGE: ${stage.name.toUpperCase()} | SEVERITY: ${severity.name.toUpperCase()}',
    );
    buf.writeln('  USER: $userMessage');
    buf.writeln('  TECH: $technicalError');
    if (stackTrace != null) buf.writeln('  STACK: $stackTrace');
    return buf.toString();
  }
}

class UiErrorStore {
  static final UiErrorStore _instance = UiErrorStore._internal();
  factory UiErrorStore() => _instance;
  UiErrorStore._internal();

  final List<UiErrorRecord> _errors = [];
  String _currentOperationId = '';

  void startOperation(String operationId) {
    _currentOperationId = operationId;
  }

  void add({
    required ErrorSource source,
    required String screen,
    required ErrorStage stage,
    required ErrorSeverity severity,
    required String userMessage,
    required dynamic error,
    StackTrace? stack,
  }) {
    try {
      TelemetryCollector().uiErrorTraces.add(
        UiErrorTrace(
          timestamp: DateTime.now(),
          screen: screen,
          userMessage: userMessage,
          technicalError: error.toString(),
          stackTrace: stack?.toString(),
        ),
      );
    } catch (_) {}

    _errors.add(
      UiErrorRecord(
        timestamp: DateTime.now(),
        operationId: _currentOperationId,
        source: source,
        screen: screen,
        stage: stage,
        severity: severity,
        userMessage: userMessage,
        technicalError: error.toString(),
        stackTrace: stack?.toString(),
      ),
    );
  }

  List<UiErrorRecord> get errors => List.unmodifiable(_errors);

  void clear() => _errors.clear();

  String dump() {
    if (_errors.isEmpty) return "None.";
    return _errors.map((e) => e.toString()).join('\n');
  }
}
