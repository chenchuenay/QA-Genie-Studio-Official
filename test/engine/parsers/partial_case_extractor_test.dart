import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';

void main() {
  group('PartialCaseExtractor', () {
    late PartialCaseExtractor extractor;

    setUp(() {
      extractor = const PartialCaseExtractor();
    });

    test('returns valid cases', () {
      final raw = [
        {'title': 'TC1', 'steps': [{'action': 'tap'}]},
        {'title': 'TC2', 'steps': [{'action': 'swipe'}]},
      ];
      final result = extractor.extractValidCases(raw);
      expect(result, hasLength(2));
    });

    test('filters out non-map entries', () {
      final raw = [42, 'string', {'title': 'TC', 'steps': [{'action': 'x'}]}];
      final errors = <String>[];
      final result = extractor.extractValidCases(raw, errors);
      expect(result, hasLength(1));
      expect(errors, hasLength(2));
      expect(errors.first, contains('not a map'));
    });

    test('rejects case with empty title', () {
      final raw = [
        {'title': '', 'steps': [{'action': 'x'}]},
      ];
      final errors = <String>[];
      final result = extractor.extractValidCases(raw, errors);
      expect(result, isEmpty);
      expect(errors.first, contains('title is empty'));
    });

    test('rejects case with missing steps', () {
      final raw = [
        {'title': 'TC', 'steps': null},
      ];
      final errors = <String>[];
      final result = extractor.extractValidCases(raw, errors);
      expect(result, isEmpty);
      expect(errors.first, contains('steps is not a'));
    });

    test('rejects case with empty steps list', () {
      final raw = [
        {'title': 'TC', 'steps': <dynamic>[]},
      ];
      final errors = <String>[];
      final result = extractor.extractValidCases(raw, errors);
      expect(result, isEmpty);
      expect(errors.first, contains('steps is not a'));
    });

    test('handles empty input list', () {
      final result = extractor.extractValidCases([]);
      expect(result, isEmpty);
    });

    test('handles null errors list gracefully', () {
      final raw = [42];
      final result = extractor.extractValidCases(raw, null);
      expect(result, isEmpty);
    });
  });
}
