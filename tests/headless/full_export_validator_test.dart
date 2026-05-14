import 'package:flutter_test/flutter_test.dart';
import 'full_export_validator.dart' as validator;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('execute validator', () async {
    await validator.runValidator();
  }, timeout: const Timeout(Duration(minutes: 5)));
}
