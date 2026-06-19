import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/dialogs/feedback_dialog.dart';

void main() {
  testWidgets('FeedbackDialog renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const FeedbackDialog()),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Help us improve'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Share'), findsOneWidget);
  });

  testWidgets('FeedbackDialog Not Now pops', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const FeedbackDialog()),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not Now'));
    await tester.pumpAndSettle();
    expect(find.text('Help us improve'), findsNothing);
  });
}
