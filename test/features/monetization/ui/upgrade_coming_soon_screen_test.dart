import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_coming_soon_screen.dart';

void main() {
  testWidgets('UpgradeComingSoonScreen renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const UpgradeComingSoonScreen(),
    ));
    expect(find.text('Upgrade to Pro'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
  });
}
