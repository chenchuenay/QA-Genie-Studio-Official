import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/widgets/native_ad_widget.dart';

void main() {
  testWidgets('NativeAdWidget renders empty when ads are real', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: NativeAdWidget())),
    ));
    await tester.pump();
    expect(find.text('Sponsored Ad'), findsNothing);
  });
}
