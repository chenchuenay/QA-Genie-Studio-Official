import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/dialogs/export_bottom_sheet.dart';

void main() {
  testWidgets('ExportBottomSheet renders options', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    addTearDown(() => tester.view.resetPhysicalSize());
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          builder: (_) => ExportBottomSheet(
            cases: [],
            moduleName: 'Test Module',
            featureName: 'Test Feature',
            onSave: (_) {},
            onExport: (_, __, ___, {bool hideEmptyColumns = false}) {},
          ),
        ),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Export Options'), findsOneWidget);
    expect(find.text('Excel'), findsOneWidget);
    expect(find.text('Jira (CSV)'), findsOneWidget);
    expect(find.text('Xray (JSON)'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
  });
}
