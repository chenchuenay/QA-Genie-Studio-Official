import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/support/ui/report_issue_screen.dart';

void main() {
  testWidgets('ReportIssueScreen renders tabs', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const ReportIssueScreen(),
    ));
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Report Issue'), findsOneWidget);
    expect(find.text('My Feedbacks'), findsOneWidget);
  });
}
