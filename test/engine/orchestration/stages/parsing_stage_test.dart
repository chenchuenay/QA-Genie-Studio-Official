import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestration/stages/parsing_stage.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';

class _MockParser extends AiResponseParser {
  final List<Map<String, dynamic>> _cases;
  final bool _malformed;
  final List<String> _errors;

  const _MockParser({
    required List<Map<String, dynamic>> cases,
    required bool malformed,
    required List<String> errors,
  }) : _cases = cases, _malformed = malformed, _errors = errors;

  @override
  ParsedAiResponse parse(String rawResponse) {
    return ParsedAiResponse(
      cases: _cases,
      salvaged: false,
      malformed: _malformed,
      parserErrors: _errors,
    );
  }
}

void main() {
  group('ParsingStage', () {
    test('execute returns empty result for empty response', () {
      final stage = ParsingStage(
        parser: const _MockParser(cases: [], malformed: false, errors: []),
      );
      final result = stage.execute(rawResponse: '');
      expect(result.parsedCases, isEmpty);
      expect(result.parserErrors, isNotEmpty);
      expect(result.malformed, isFalse);
    });

    test('execute returns empty result for whitespace-only response', () {
      final stage = ParsingStage(
        parser: const _MockParser(cases: [], malformed: false, errors: []),
      );
      final result = stage.execute(rawResponse: '   ');
      expect(result.parsedCases, isEmpty);
    });

    test('execute delegates to parser for non-empty response', () {
      final stage = ParsingStage(
        parser: const _MockParser(
          cases: [{'id': 'TC_001'}],
          malformed: false,
          errors: [],
        ),
      );
      final result = stage.execute(rawResponse: 'some response');
      expect(result.parsedCases.length, equals(1));
      expect(result.parsedCases[0]['id'], equals('TC_001'));
      expect(result.malformed, isFalse);
    });

    test('execute propagates malformed flag from parser', () {
      final stage = ParsingStage(
        parser: const _MockParser(cases: [], malformed: true, errors: ['Parse error']),
      );
      final result = stage.execute(rawResponse: 'bad response');
      expect(result.malformed, isTrue);
      expect(result.parserErrors, contains('Parse error'));
    });

    test('execute propagates parser errors', () {
      final stage = ParsingStage(
        parser: const _MockParser(
          cases: [{'id': 'TC_001'}],
          malformed: false,
          errors: ['Warning: field missing'],
        ),
      );
      final result = stage.execute(rawResponse: 'response');
      expect(result.parserErrors, contains('Warning: field missing'));
    });
  });
}
