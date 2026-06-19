import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/qa_button.dart';

void main() {
  testWidgets('QAButton renders text', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: QAButton(
        onPressed: () {},
        text: 'Generate',
      ))),
    ));
    expect(find.text('Generate'), findsOneWidget);
  });

  testWidgets('QAButton shows loading indicator', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: QAButton(
        onPressed: () {},
        text: 'Generate',
        loading: true,
      ))),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Generate'), findsNothing);
  });

  testWidgets('QAButton with icon renders icon', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: QAButton(
        onPressed: () {},
        text: 'Go',
        icon: Icons.bolt,
      ))),
    ));
    expect(find.text('Go'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('QAButton disabled when loading', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: QAButton(
        onPressed: () { tapped = true; },
        text: 'Tap',
        loading: true,
      ))),
    ));
    await tester.tap(find.byType(ElevatedButton));
    expect(tapped, false);
  });
}
