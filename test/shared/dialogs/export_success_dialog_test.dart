import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/dialogs/export_success_dialog.dart';
import '../../firebase/firebase_test_helper.dart';

void main() {
  setUpAll(() async => await setupFirebaseMocks());

  testWidgets('ExportSuccessDialog renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const ExportSuccessDialog(
          type: 'excel',
          moduleName: 'Test Module',
        )),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Export Complete'), findsOneWidget);
    expect(find.textContaining('Test Module'), findsOneWidget);
  });
}
