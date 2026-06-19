import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';

void main() {
  group('AiResponseParser', () {
    late AiResponseParser parser;

    setUp(() {
      parser = const AiResponseParser();
    });

    test('returns errors for empty response', () {
      final result = parser.parse('');
      expect(result.cases, isEmpty);
      expect(result.parserErrors, isNotEmpty);
      expect(result.parserErrors.first, contains('empty'));
      expect(result.malformed, isFalse);
      expect(result.salvaged, isFalse);
    });

    test('parses valid JSON array', () {
      const raw =
          '[{"title": "Test 1", "steps": [{"action": "tap"}], "expectedResult": "pass"}]';
      final result = parser.parse(raw);
      expect(result.cases, hasLength(1));
      expect(result.cases.first['title'], 'Test 1');
      expect(result.malformed, isFalse);
      expect(result.salvaged, isFalse);
      expect(result.parserErrors, isEmpty);
    });

    test('parses JSON array with surrounding text', () {
      const raw =
          'Some text\n[{"title": "TC1", "steps": [{"action": "click"}]}]\nend';
      final result = parser.parse(raw);
      expect(result.cases, hasLength(1));
      expect(result.cases.first['title'], 'TC1');
    });

    test('extracts testCases from map response', () {
      const raw = '{"testCases": [{"title": "A", "steps": [{"action": "do"}]}]}';
      final result = parser.parse(raw);
      expect(result.cases, hasLength(1));
      expect(result.cases.first['title'], 'A');
    });

    test('reports missing testCases key in map', () {
      const raw = '{"other": []}';
      final result = parser.parse(raw);
      expect(result.cases, isEmpty);
      expect(result.malformed, isTrue);
    });

    test('handles malformed JSON via salvage', () {
      const raw =
          '[{"title": "TC", "steps": [{"action": "do"}]';
      final result = parser.parse(raw);
      expect(result.cases, hasLength(1));
      expect(result.salvaged, isTrue);
    });

    test('fails completely when salvage also fails', () {
      const raw = 'totally broken {{{';
      final result = parser.parse(raw);
      expect(result.cases, isEmpty);
      expect(result.malformed, isTrue);
      expect(result.salvaged, isTrue);
      expect(result.parserErrors, hasLength(4));
    });

    test('handles non-array non-map decoded type', () {
      const raw = '"just a string"';
      final result = parser.parse(raw);
      expect(result.cases, isEmpty);
      expect(result.malformed, isTrue);
      expect(
        result.parserErrors.any((e) => e.contains('neither array nor object')),
        isTrue,
      );
    });
  });
}
