import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/app/app.dart';

void main() {
  testWidgets('QaGenieApp creates MaterialApp', (tester) async {
    await tester.pumpWidget(const QaGenieApp());
    expect(find.byType(QaGenieApp), findsOneWidget);
    // Drain pending timeout timers from splash screen background work
    await tester.pump(const Duration(seconds: 5));
  });
}
