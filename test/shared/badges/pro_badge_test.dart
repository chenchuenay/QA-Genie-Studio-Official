import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/badges/pro_badge.dart';

void main() {
  testWidgets('ProBadge shows PRO for isPro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: ProBadge(isPro: true))),
    ));
    expect(find.text('PRO'), findsOneWidget);
  });

  testWidgets('ProBadge shows CORE for not isPro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: ProBadge(isPro: false))),
    ));
    expect(find.text('CORE'), findsOneWidget);
  });
}
