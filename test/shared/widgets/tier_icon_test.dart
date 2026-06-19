import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/tier_icon.dart';

void main() {
  testWidgets('TierIcon shows star for core', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: TierIcon(isPro: false))),
    ));
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('TierIcon shows star for pro', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: TierIcon(isPro: true))),
    ));
    expect(find.byIcon(Icons.star), findsOneWidget);
  });
}
