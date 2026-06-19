import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/account/ui/account_screen.dart';
import '../../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

  testWidgets('AccountScreen renders app bar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const AccountScreen(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    tester.takeException();
    expect(find.text('Account'), findsOneWidget);
  });
}
