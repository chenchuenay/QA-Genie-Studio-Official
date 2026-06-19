import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/features/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders logo and title', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: const SplashScreen(),
    ));
    expect(find.text('QA Genie'), findsOneWidget);
  });
}
