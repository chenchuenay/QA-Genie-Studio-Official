import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/forensics/trace_id_generator.dart';

void main() {
  group('TraceIdGenerator', () {
    test('generate returns trace ID with correct format', () {
      final id = TraceIdGenerator.generate();
      expect(id, startsWith('TRACE-'));
      expect(id, contains('-CORE-'));
      expect(id, contains('-GEN-'));
    });

    test('generate includes timestamp and random hex', () {
      final id = TraceIdGenerator.generate();
      final parts = id.split('-');
      expect(parts.length, greaterThanOrEqualTo(5));
      expect(int.tryParse(parts[parts.length - 2]), isNotNull);
    });

    test('generate accepts custom tier', () {
      final id = TraceIdGenerator.generate(tier: 'PRO');
      expect(id, contains('-PRO-'));
    });

    test('generate accepts custom platform', () {
      final id = TraceIdGenerator.generate(platform: 'iOS');
      expect(id, contains('-IOS-'));
    });

    test('generate normalizes tier to uppercase', () {
      final id = TraceIdGenerator.generate(tier: 'core');
      expect(id, contains('-CORE-'));
    });

    test('generate normalizes platform to uppercase', () {
      final id = TraceIdGenerator.generate(platform: 'android');
      expect(id, contains('-ANDROID-'));
    });

    test('generate strips invalid characters from tier', () {
      final id = TraceIdGenerator.generate(tier: 'CORE-TIER!');
      expect(id, contains('-CORETIER-'));
      expect(id, isNot(contains('!')));
    });

    test('generate strips invalid characters from platform', () {
      final id = TraceIdGenerator.generate(platform: 'GEN@FORM');
      expect(id, contains('-GENFORM-'));
    });

    test('generate trims whitespace from tier', () {
      final id = TraceIdGenerator.generate(tier: '  PRO  ');
      expect(id, contains('-PRO-'));
    });

    test('short returns ID with QG- prefix', () {
      final id = TraceIdGenerator.short();
      expect(id, startsWith('QG-'));
    });

    test('short returns 8-char hex after prefix', () {
      final id = TraceIdGenerator.short();
      final suffix = id.substring(3);
      expect(suffix.length, 8);
      expect(int.tryParse(suffix, radix: 16), isNotNull);
    });

    test('generate produces unique IDs', () {
      final ids = <String>{};
      for (int i = 0; i < 10; i++) {
        ids.add(TraceIdGenerator.generate());
      }
      expect(ids.length, 10);
    });

    test('short produces unique IDs', () {
      final ids = <String>{};
      for (int i = 0; i < 10; i++) {
        ids.add(TraceIdGenerator.short());
      }
      expect(ids.length, 10);
    });
  });
}
