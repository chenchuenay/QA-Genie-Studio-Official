import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/support/ui/report_issue_screen.dart';

void main() {
  testWidgets('ReportIssueScreen shows sign-in prompt for guests', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const ReportIssueScreen(),
    ));
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('Sign in to submit a report'), findsOneWidget);
    expect(find.text('Only signed-in users can submit a report. '
        'Sign in with Google to share your feedback and track its status.'), findsOneWidget);
  });
}
