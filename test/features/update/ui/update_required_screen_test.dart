import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/update/ui/update_required_screen.dart';
import 'package:qa_genie/features/update/logic/update_manager.dart';

void main() {
  testWidgets('UpdateRequiredScreen renders blocked update', (tester) async {
    final check = UpdateCheckResult(
      updateRequired: true,
      latestVersion: '2.0.0',
      latestBuild: '200',
      blockBelowBuild: '200',
      updateUrl: 'https://play.google.com/store/apps/details?id=com.enaykumar.qagenie',
      dismissCount: 3,
      blocked: true,
    );
    await tester.pumpWidget(MaterialApp(
      home: UpdateRequiredScreen(check: check),
    ));
    await tester.pump();
    expect(find.text('Update Required'), findsOneWidget);
    expect(find.text('Update Now'), findsOneWidget);
  });

  testWidgets('UpdateRequiredScreen renders non-blocked update', (tester) async {
    final check = UpdateCheckResult(
      updateRequired: true,
      latestVersion: '2.0.0',
      latestBuild: '200',
      blockBelowBuild: '150',
      updateUrl: 'https://play.google.com/store/apps/details?id=com.enaykumar.qagenie',
      dismissCount: 0,
      blocked: false,
    );
    await tester.pumpWidget(MaterialApp(
      home: UpdateRequiredScreen(check: check),
    ));
    await tester.pump();
    expect(find.text('Update Available'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
  });
}
