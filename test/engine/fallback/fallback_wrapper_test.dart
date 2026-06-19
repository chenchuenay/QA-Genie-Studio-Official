import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/fallback/fallback_wrapper.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';

void main() {
  group('FallbackWrapper', () {
    test('generateMissing returns empty when missingCount is 0', () async {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 5,
        traceId: 'trace-1',
      );
      final result = await FallbackWrapper.generateMissing(
        request: request,
        missingCount: 0,
        missingOutcomes: [],
        existingCount: 5,
      );
      expect(result, isEmpty);
    });

    test('generateMissing returns empty when missingCount is negative', () async {
      final request = GenerationRequest(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        generationMode: 'core',
        requestedCaseCount: 5,
        traceId: 'trace-1',
      );
      final result = await FallbackWrapper.generateMissing(
        request: request,
        missingCount: -1,
        missingOutcomes: [],
        existingCount: 5,
      );
      expect(result, isEmpty);
    });
  });
}
