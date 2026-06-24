import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/legal/ui/about_screen.dart';

void main() {
  testWidgets('AboutScreen renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const AboutScreen(),
    ));
    await tester.pump();
    expect(find.text('About'), findsOneWidget);
    expect(find.text('QA Genie'), findsOneWidget);
    expect(find.text('Hybrid-Powered Test Flow Engine'), findsOneWidget);
  });
}
