import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/effects/press_effect.dart';

void main() {
  testWidgets('PressEffect renders child and handles tap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: PressEffect(
        onTap: () { tapped = true; },
        child: const Text('Tap Me'),
      ))),
    ));
    expect(find.text('Tap Me'), findsOneWidget);
    await tester.tap(find.text('Tap Me'));
    expect(tapped, true);
  });
}
