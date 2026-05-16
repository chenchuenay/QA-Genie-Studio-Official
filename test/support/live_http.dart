import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Installs real `dart:io` sockets for live provider tests (`flutter test` stubs HTTP otherwise).
class QaGenieLiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // Must not call `HttpClient()` here — that re-enters this override (stack overflow).
    final client = super.createHttpClient(context);
    client.idleTimeout = const Duration(seconds: 120);
    client.connectionTimeout = const Duration(seconds: 45);
    return client;
  }
}

void ensureLiveGroqNetworking() {
  // Binding install calls `setupHttpOverrides()` → mock HTTP 400. Install binding
  // first, then replace global overrides so Groq/`package:http` use a real client.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = QaGenieLiveHttpOverrides();
}
