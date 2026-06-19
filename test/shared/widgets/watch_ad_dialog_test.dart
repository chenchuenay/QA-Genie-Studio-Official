import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/watch_ad_dialog.dart';

void main() {
  testWidgets('WatchAdDialog renders feature name', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => const WatchAdDialog(featureName: 'Export Test Cases')),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Export Test Cases'), findsOneWidget);
    expect(find.text('No Thanks'), findsOneWidget);
    expect(find.text('Watch Ad'), findsOneWidget);
  });

  testWidgets('WatchAdDialog No Thanks returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<bool>(context: context, builder: (_) => const WatchAdDialog(featureName: 'Test'));
        },
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('No Thanks'));
    await tester.pumpAndSettle();
    expect(result, false);
  });

  testWidgets('WatchAdDialog Watch Ad returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () async {
          result = await showDialog<bool>(context: context, builder: (_) => const WatchAdDialog(featureName: 'Test'));
        },
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watch Ad'));
    await tester.pumpAndSettle();
    expect(result, true);
  });
}
