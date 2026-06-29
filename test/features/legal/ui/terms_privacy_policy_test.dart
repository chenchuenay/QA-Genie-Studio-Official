import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/legal/ui/terms_privacy_policy.dart';

void main() {
  testWidgets('TermsPrivacyPolicyScreen renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const TermsPrivacyPolicyScreen(),
    ));
    expect(find.text('Policies'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('AI Disclaimer'), findsOneWidget);
    expect(find.text('Ads & Monetization'), findsOneWidget);
  });
}
