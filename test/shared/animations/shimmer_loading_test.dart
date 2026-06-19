import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/animations/shimmer_loading.dart';

void main() {
  testWidgets('ShimmerLoading renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: ShimmerLoading())),
    ));
    await tester.pump();
    expect(find.byType(ShimmerLoading), findsOneWidget);
  });

  testWidgets('GenerateButtonLoading renders', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: GenerateButtonLoading())),
    ));
    await tester.pump();
    expect(find.text('Generating...'), findsOneWidget);
  });
}
