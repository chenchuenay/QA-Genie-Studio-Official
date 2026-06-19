import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/dialogs/ad_loading_dialog.dart';

void main() {
  testWidgets('AdLoadingDialog renders title and message', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AdLoadingDialog(onRetry: _dummy)),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Ad Not Ready'), findsOneWidget);
    expect(find.text('Later'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('AdLoadingDialog custom title and message', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AdLoadingDialog(
          onRetry: _dummy,
          title: 'Custom Title',
          message: 'Custom message here.',
        )),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Custom Title'), findsOneWidget);
    expect(find.text('Custom message here.'), findsOneWidget);
  });

  testWidgets('AdLoadingDialog Later pops dialog', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const AdLoadingDialog(onRetry: _dummy)),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
    expect(find.text('Ad Not Ready'), findsNothing);
  });
}

void _dummy() {}
