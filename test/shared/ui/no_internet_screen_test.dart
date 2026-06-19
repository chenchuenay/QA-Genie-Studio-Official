import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/shared/ui/no_internet_screen.dart';

void main() {
  testWidgets('NoInternetScreen renders correctly', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const NoInternetScreen(),
          ),
          child: const Text('Show'),
        ),
      ),
    ));

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('CONNECT TO INTERNET'), findsOneWidget);
    expect(find.text('Retry Connection'), findsOneWidget);
    expect(find.text('Continue Offline'), findsOneWidget);
  });
}
