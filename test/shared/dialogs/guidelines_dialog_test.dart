import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/shared/dialogs/guidelines_dialog.dart';

void main() {
  testWidgets('GuidelinesDialog renders tips', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const GuidelinesDialog()),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('How to get the best test cases'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('GuidelinesDialog with tour button', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => GuidelinesDialog(
          onStartWalkthrough: () {},
          showTourButton: true,
        )),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Take a Quick Tour'), findsOneWidget);
  });
}
