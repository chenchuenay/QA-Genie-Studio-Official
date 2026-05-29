import 'dart:async';

class UiErrorEvent {
  final String id;

  final String title;

  final String message;

  final String category;

  final DateTime timestamp;

  final Object? exception;

  final StackTrace? stackTrace;

  final bool isFatal;

  const UiErrorEvent({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.exception,
    this.stackTrace,
    this.isFatal = false,
  });

  UiErrorEvent copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    DateTime? timestamp,
    Object? exception,
    StackTrace? stackTrace,
    bool? isFatal,
  }) {
    return UiErrorEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      exception: exception ?? this.exception,
      stackTrace: stackTrace ?? this.stackTrace,
      isFatal: isFatal ?? this.isFatal,
    );
  }
}

class UiErrorStore {
  UiErrorStore._();

  static final StreamController<UiErrorEvent> _streamController =
      StreamController<UiErrorEvent>.broadcast();

  static final List<UiErrorEvent> _history = [];

  static Stream<UiErrorEvent> get stream => _streamController.stream;

  static List<UiErrorEvent> get history => List.unmodifiable(_history);

  static void push(UiErrorEvent event) {
    _history.insert(0, event);

    if (_history.length > 200) {
      _history.removeRange(200, _history.length);
    }

    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }

  static void clear() {
    _history.clear();
  }

  static Future<void> dispose() async {
    await _streamController.close();
  }
}
