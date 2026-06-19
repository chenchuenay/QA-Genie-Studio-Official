import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/adapters/csv_adapter.dart';

FinalizedTestCase _makeCase({
  String id = 'TC-001',
  String title = 'Test login',
  String module = 'Auth',
  String feature = 'Login',
}) {
  return FinalizedTestCase(
    dbId: 1,
    id: id,
    title: title,
    module: module,
    feature: feature,
    platform: 'Android',
    priority: 'High',
    expectedResult: 'Success',
    type: 'Functional',
    steps: [TestStep(action: 'Click login', data: '', expected: 'Success')],
    preconditions: [],
    testData: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CsvAdapter', () {
    test('export throws when FileWriter fails', () async {
      final cases = [_makeCase()];
      await expectLater(
        () => CsvAdapter.export(cases, fileName: '', moduleName: '', featureName: ''),
        throwsA(isA<Exception>()),
      );
    });

    test('export with empty fileName throws', () async {
      final cases = [_makeCase()];
      await expectLater(
        () => CsvAdapter.export(cases, fileName: '', moduleName: 'Auth', featureName: 'Login'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
