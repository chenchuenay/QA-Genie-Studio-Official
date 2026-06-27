import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/dialogs/export_preview_dialog.dart';

void main() {
  testWidgets('ExportPreviewDialog renders without cases', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (context) => ElevatedButton(
        onPressed: () => showDialog(context: context, builder: (_) => ExportPreviewDialog(
          type: 'excel',
          cases: [],
          moduleName: 'M',
          featureName: 'F',
          onSave: (_) {},
          onShare: (_, __, {bool hideEmptyColumns = false}) async {},
        )),
        child: const Text('show'),
      )),
    ));
    await tester.tap(find.text('show'));
    await tester.pumpAndSettle();
    expect(find.text('Export Preview • Excel'), findsOneWidget);
  });
}
