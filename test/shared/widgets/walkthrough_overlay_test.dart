import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/walkthrough_overlay.dart';

void main() {
  testWidgets('WalkthroughOverlay shows steps via show', (tester) async {
    final key1 = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(builder: (context) {
          return Column(children: [
            Text('Test', key: key1),
            ElevatedButton(
              onPressed: () => WalkthroughOverlay.show(
                context: context,
                steps: [
                  WalkthroughStep(
                    key: key1,
                    icon: Icons.edit,
                    title: 'Step One',
                    description: 'First step description',
                  ),
                ],
              ),
              child: const Text('Start'),
            ),
          ]);
        }),
      ),
    ));
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Step One'), findsOneWidget);
    expect(find.text('First step description'), findsOneWidget);
  });
}
