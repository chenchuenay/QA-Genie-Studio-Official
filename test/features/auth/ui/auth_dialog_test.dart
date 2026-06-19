import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import '../../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

  testWidgets('AuthDialog renders with guest button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog(showGuestButton: true)),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
  });

  testWidgets('AuthDialog hides guest button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AuthDialog(showGuestButton: false)),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsNothing);
  });
}
