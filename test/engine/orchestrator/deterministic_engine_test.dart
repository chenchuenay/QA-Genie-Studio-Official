import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/orchestrator/deterministic_engine.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

void main() {
  group('DeterministicEngine', () {
    test('constructor sets fields correctly', () {
      final engine = DeterministicEngine(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        constraints: 'test constraint',
        targetCount: 5,
        mode: GenerationMode.core,
      );
      expect(engine.module, equals('Auth'));
      expect(engine.feature, equals('Login'));
      expect(engine.platform, equals('WEB'));
      expect(engine.constraints, equals('test constraint'));
      expect(engine.targetCount, equals(5));
      expect(engine.mode, equals(GenerationMode.core));
    });

    test('constructor uses default mode', () {
      final engine = DeterministicEngine(
        module: 'Test',
        feature: 'Test',
        platform: 'WEB',
        targetCount: 1,
      );
      expect(engine.mode, equals(GenerationMode.core));
    });

    test('generate returns cases for a known feature', () async {
      final engine = DeterministicEngine(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        targetCount: 1,
      );
      final result = await engine.generate();
      expect(result, isNotEmpty);
    });

    test('generate respects targetCount', () async {
      final engine = DeterministicEngine(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        targetCount: 3,
      );
      final result = await engine.generate();
      expect(result.length, equals(3));
    });

    test('generate returns cases with required fields', () async {
      final engine = DeterministicEngine(
        module: 'Auth',
        feature: 'Login',
        platform: 'WEB',
        targetCount: 1,
      );
      final result = await engine.generate();
      expect(result[0].title, isNotEmpty);
      expect(result[0].steps, isNotEmpty);
      expect(result[0].expectedResult, isNotEmpty);
    });
  });
}
