import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/navigation/main_screen.dart';
import '../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

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
