import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/legal/ui/document_view_screen.dart';

void main() {
  testWidgets('DocumentViewScreen renders title and content', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const DocumentViewScreen(
        title: 'Privacy Policy',
        content: 'This is the privacy policy content.',
      ),
    ));
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('This is the privacy policy content.'), findsOneWidget);
  });

  testWidgets('DocumentViewScreen shows online link when url provided', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const DocumentViewScreen(
        title: 'Terms',
        content: 'Terms content.',
        onlineUrl: 'https://example.com',
      ),
    ));
    expect(find.text('View Full Policy Online'), findsOneWidget);
  });
}
