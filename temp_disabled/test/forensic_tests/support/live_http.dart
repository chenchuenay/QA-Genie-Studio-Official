import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

class QaGenieLiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionTimeout = const Duration(seconds: 45);
    client.idleTimeout = const Duration(seconds: 120);
    return client;
  }
}

void ensureLiveNetworking() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = QaGenieLiveHttpOverrides();
}
