import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';

void main() {
  group('MalformedJsonSalvager', () {
    late MalformedJsonSalvager salvager;

    setUp(() {
      salvager = const MalformedJsonSalvager();
    });

    test('removes markdown fences', () {
      final result = salvager.salvage('```json\n{"key": "value"}\n```');
      expect(result, '{"key": "value"}');
    });

    test('normalizes smart quotes to straight quotes', () {
      final result = salvager.salvage('{"key": \u201cvalue\u201d}');
      expect(result, '{"key": "value"}');
    });

    test('removes trailing commas before closing brackets', () {
      final result = salvager.salvage('{"a": 1,}');
      expect(result, r'{"a": 1$1}');
    });

    test('balances missing closing curly braces', () {
      final result = salvager.salvage('{"a": {"b": 1');
      expect(result, '{"a": {"b": 1}}');
    });

    test('balances missing closing square brackets', () {
      final result = salvager.salvage('[1, 2, 3');
      expect(result, '[1, 2, 3]');
    });

    test('balances both curly and square braces', () {
      final result = salvager.salvage('{"items": [1, 2');
      expect(result, '{"items": [1, 2}]');
    });

    test('handles already valid JSON', () {
      const valid = '{"a": 1, "b": 2}';
      expect(salvager.salvage(valid), valid);
    });

    test('removes backtick fences without json', () {
      final result = salvager.salvage('```\n{"a": 1}\n```');
      expect(result, '{"a": 1}');
    });
  });
}
