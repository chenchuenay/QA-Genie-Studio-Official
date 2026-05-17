import 'dart:io';
import 'dart:math';

enum ErrorSeverity { info, warning, error, critical }

class UiErrorRecord {
  final DateTime timestamp;
  final String operationId; // matches a generation batch
  final String source; // e.g., generation_pipeline, export_engine, ui_preview
  final String screen; // screen name if applicable
  final String
  stage; // REQUEST, RAW_RESPONSE, PARSE, REPAIR, VALIDATION, EXPORT, UI_RENDER
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
      '[$timestamp] OP: $operationId | SOURCE: $source | SCREEN: $screen | STAGE: $stage | SEVERITY: ${severity.name.toUpperCase()}',
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
    required String source,
    required String screen,
    required String stage,
    required ErrorSeverity severity,
    required String userMessage,
    required dynamic error,
    StackTrace? stack,
  }) {
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
