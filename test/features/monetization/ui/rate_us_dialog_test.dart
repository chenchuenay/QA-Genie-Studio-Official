import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ui/rate_us_dialog.dart';

void main() {
  testWidgets('showRateUsDialog renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showRateUsDialog(context),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Enjoying QA Genie Studio?'), findsOneWidget);
    expect(find.text('Not Now'), findsOneWidget);
    expect(find.text('Rate Now'), findsOneWidget);
  });
}
