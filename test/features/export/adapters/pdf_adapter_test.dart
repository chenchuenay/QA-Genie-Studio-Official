import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';
import 'package:qa_genie/features/export/adapters/pdf_adapter.dart';

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

  group('PdfAdapter', () {
    test('export throws for empty cases list', () async {
      await expectLater(
        () => PdfAdapter.export([], fileName: 'test', moduleName: 'M', featureName: 'F'),
        throwsA(isA<Exception>()),
      );
    });

    test('export with invalid fileName throws', () async {
      final cases = [_makeCase()];
      await expectLater(
        () => PdfAdapter.export(cases, fileName: '', moduleName: 'M', featureName: 'F'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
