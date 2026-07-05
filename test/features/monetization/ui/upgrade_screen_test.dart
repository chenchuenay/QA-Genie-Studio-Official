import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_screen.dart';
import '../../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

  testWidgets('UpgradeScreen renders for non-pro users', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const UpgradeScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('QA Genie Studio Pro'), findsOneWidget);
  });
}
