
class UiErrorRecord {
  final DateTime timestamp;
  final String screen;
  final String userMessage;
  final String technicalError;
  final String? stackTrace;
  UiErrorRecord({
    required this.timestamp,
    required this.screen,
    required this.userMessage,
    required this.technicalError,
    this.stackTrace,
  });
  @override
  String toString() {
    var buf = StringBuffer();
    buf.writeln('[${timestamp.toIso8601String()}] SCREEN: $screen');
    buf.writeln('  USER: $userMessage');
    buf.writeln('  TECH: $technicalError');
    if (stackTrace != null) buf.writeln('  STACK: $stackTrace');
    return buf.toString();
  }
}
