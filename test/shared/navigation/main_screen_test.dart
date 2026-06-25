import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import 'package:qa_genie/core/database/database_service.dart';
import '../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathChannel,
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
    await setupFirebaseMocks();
    await DatabaseService.initDatabase('test_identity');
  });

  testWidgets('MainScreen renders with scaffold', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const MainScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 11));
    tester.takeException();
    expect(find.text('QA Genie Studio'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Suites'), findsOneWidget);
  });
}
