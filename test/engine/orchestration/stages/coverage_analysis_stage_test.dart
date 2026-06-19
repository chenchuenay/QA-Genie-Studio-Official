import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestration/stages/coverage_analysis_stage.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

WorkingCase makeCase({
  String id = 'TC_001',
  String categoryLock = 'positive',
  String type = 'POSITIVE',
  String intentId = '',
}) {
  return WorkingCase(
    id: id,
    title: 'Test case $id',
    module: 'Auth',
    feature: 'Login',
    platform: 'WEB',
    priority: 'High',
    type: type,
    categoryLock: categoryLock,
    preconditions: [],
    testData: '',
    steps: [TestStep(action: 'action', data: '', expected: 'expected')],
    expectedResult: 'Success',
    actualResult: '',
    status: '',
    metadata: CaseMetadata(source: CaseSource.ai, traceId: 'trace-1', intentId: intentId),
    intentId: intentId,
  );
}

void main() {
  group('CoverageAnalysisStage', () {
    late CoverageAnalysisStage stage;

    setUp(() {
      stage = const CoverageAnalysisStage();
    });

    test('execute returns full coverage when all cases accepted', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 2,
        plan: [
          {'category': 'positive', 'intent_id': 'valid_login'},
          {'category': 'negative', 'intent_id': 'invalid_login'},
        ],
        traceId: 'trace-1',
      );
      final cases = [
        makeCase(id: 'TC_001', categoryLock: 'positive', intentId: 'valid_login'),
        makeCase(id: 'TC_002', categoryLock: 'negative', intentId: 'invalid_login'),
      ];
      final result = stage.execute(request: request, acceptedCases: cases);
      expect(result.missingCount, equals(0));
      expect(result.needsFallback, isFalse);
      expect(result.requiresFullFallback, isFalse);
    });

    test('execute returns missing count when not enough cases', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 5,
        plan: [
          {'category': 'positive', 'intent_id': 'test_1'},
          {'category': 'positive', 'intent_id': 'test_2'},
          {'category': 'positive', 'intent_id': 'test_3'},
          {'category': 'positive', 'intent_id': 'test_4'},
          {'category': 'positive', 'intent_id': 'test_5'},
        ],
        traceId: 'trace-1',
      );
      final cases = [makeCase()];
      final result = stage.execute(request: request, acceptedCases: cases);
      expect(result.missingCount, equals(4));
      expect(result.needsFallback, isTrue);
    });

    test('execute requires full fallback when no accepted cases', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 3,
        plan: [
          {'category': 'positive', 'intent_id': 't1'},
          {'category': 'positive', 'intent_id': 't2'},
          {'category': 'positive', 'intent_id': 't3'},
        ],
        traceId: 'trace-1',
      );
      final result = stage.execute(request: request, acceptedCases: []);
      expect(result.requiresFullFallback, isTrue);
      expect(result.missingCount, equals(3));
    });

    test('execute does not require full fallback when some cases exist', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 5,
        plan: [
          {'category': 'positive', 'intent_id': 't1'},
          {'category': 'positive', 'intent_id': 't2'},
        ],
        traceId: 'trace-1',
      );
      final cases = [makeCase()];
      final result = stage.execute(request: request, acceptedCases: cases);
      expect(result.requiresFullFallback, isFalse);
    });

    test('execute computes missing category counts', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 2,
        plan: [
          {'category': 'positive', 'intent_id': 'a'},
          {'category': 'negative', 'intent_id': 'b'},
        ],
        traceId: 'trace-1',
      );
      final cases = [makeCase(categoryLock: 'positive')];
      final result = stage.execute(request: request, acceptedCases: cases);
      expect(result.missingCategoryCounts, containsPair('negative', 1));
      expect(result.missingCategoryCounts, isNot(contains('positive')));
    });

    test('execute populates target category counts', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 2,
        plan: [
          {'category': 'positive', 'intent_id': 'a'},
          {'category': 'negative', 'intent_id': 'b'},
        ],
        traceId: 'trace-1',
      );
      final result = stage.execute(request: request, acceptedCases: []);
      expect(result.targetCategoryCounts, containsPair('positive', 1));
      expect(result.targetCategoryCounts, containsPair('negative', 1));
    });

    test('execute finds missing outcomes', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 2,
        plan: [
          {'category': 'positive', 'intent_id': 'valid_login'},
          {'category': 'negative', 'intent_id': 'invalid_login'},
        ],
        traceId: 'trace-1',
      );
      final cases = [makeCase(categoryLock: 'positive', intentId: 'valid_login')];
      final result = stage.execute(request: request, acceptedCases: cases);
      expect(result.missingOutcomes, contains('invalid_login'));
    });

    test('execute handles empty plan gracefully', () {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 3,
        plan: [],
        traceId: 'trace-1',
      );
      final result = stage.execute(request: request, acceptedCases: []);
      expect(result.missingCount, equals(3));
      expect(result.missingOutcomes, isEmpty);
    });
  });
}
