import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ui/test_mode_screen.dart';
import '../../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

  testWidgets('TestModeScreen renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const TestModeScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Account (Test Mode)'), findsOneWidget);
  });
}
