import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/animated_dots.dart';

void main() {
  testWidgets('AnimatedDots renders label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: AnimatedDots(
        label: 'Processing',
        style: const TextStyle(color: Colors.black),
      ))),
    ));
    await tester.pump();
    expect(find.text('Processing'), findsOneWidget);
  });
}
