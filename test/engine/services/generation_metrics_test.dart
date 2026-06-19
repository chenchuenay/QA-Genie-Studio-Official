import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/services/generation_metrics.dart';

void main() {
  group('GenerationMetrics', () {
    final baseMetrics = GenerationMetrics(
      requestedCount: 10,
      generatedCount: 8,
      finalizedCount: 6,
      rejectedCount: 2,
      repairedCount: 1,
      fallbackCount: 0,
      emergencyRecoveredCount: 0,
      structuralRejected: 1,
      semanticRejected: 1,
      realismRejected: 0,
      exportSafetyRejected: 0,
      totalDurationMs: 1000,
      aiLatencyMs: 500,
      validationLatencyMs: 200,
      repairLatencyMs: 100,
      exportSafetyLatencyMs: 50,
      estimatedPromptTokens: 500,
      estimatedCompletionTokens: 300,
      estimatedTotalTokens: 800,
      usedFallback: false,
      usedEmergencyRecovery: false,
      generationSuccessful: true,
      averageConfidenceScore: 0.85,
      traceId: 'trace-123',
      generatedAt: DateTime(2026, 1, 1),
    );

    test('empty factory creates all-zero metrics', () {
      final empty = GenerationMetrics.empty();
      expect(empty.requestedCount, equals(0));
      expect(empty.generatedCount, equals(0));
      expect(empty.finalizedCount, equals(0));
      expect(empty.traceId, isEmpty);
    });

    test('failed factory creates failed metrics', () {
      final failed = GenerationMetrics.failed(traceId: 'fail-1');
      expect(failed.generationSuccessful, isFalse);
      expect(failed.traceId, equals('fail-1'));
    });

    test('successRate returns finalized/requested', () {
      expect(baseMetrics.successRate, closeTo(0.6, 0.01));
    });

    test('successRate returns 0 when requestedCount is 0', () {
      final m = GenerationMetrics.empty();
      expect(m.successRate, equals(0));
    });

    test('rejectionRate returns rejected/generated', () {
      expect(baseMetrics.rejectionRate, closeTo(0.25, 0.01));
    });

    test('rejectionRate returns 0 when generatedCount is 0', () {
      final m = GenerationMetrics.empty();
      expect(m.rejectionRate, equals(0));
    });

    test('isHealthy returns true when successful and low rejection', () {
      expect(baseMetrics.isHealthy, isTrue);
    });

    test('isHealthy returns false when generation fails', () {
      final m = baseMetrics.copyWith(generationSuccessful: false);
      expect(m.isHealthy, isFalse);
    });

    test('hasSevereRejection returns true when rejectionRate >= 0.7', () {
      final m = GenerationMetrics(
        requestedCount: 10,
        generatedCount: 10,
        finalizedCount: 2,
        rejectedCount: 7,
        repairedCount: 0,
        fallbackCount: 0,
        emergencyRecoveredCount: 0,
        structuralRejected: 0,
        semanticRejected: 0,
        realismRejected: 0,
        exportSafetyRejected: 0,
        totalDurationMs: 0,
        usedFallback: false,
        generationSuccessful: true,
        traceId: 't',
        generatedAt: DateTime.now(),
      );
      expect(m.hasSevereRejection, isTrue);
    });

    test('estimateTokens returns ceil(length/4)', () {
      expect(GenerationMetrics.estimateTokens(''), equals(0));
      expect(GenerationMetrics.estimateTokens('abcd'), equals(1));
      expect(GenerationMetrics.estimateTokens('abcdef'), equals(2));
    });

    test('copyWith preserves unchanged fields', () {
      final m = baseMetrics.copyWith();
      expect(m.traceId, equals('trace-123'));
      expect(m.requestedCount, equals(10));
    });

    test('copyWith overrides specified fields', () {
      final m = baseMetrics.copyWith(traceId: 'new-trace', finalizedCount: 8);
      expect(m.traceId, equals('new-trace'));
      expect(m.finalizedCount, equals(8));
      expect(m.requestedCount, equals(10));
    });

    test('toJson and fromJson round-trip', () {
      final json = baseMetrics.toJson();
      final restored = GenerationMetrics.fromJson(json);
      expect(restored.requestedCount, equals(baseMetrics.requestedCount));
      expect(restored.generatedCount, equals(baseMetrics.generatedCount));
      expect(restored.finalizedCount, equals(baseMetrics.finalizedCount));
      expect(restored.traceId, equals(baseMetrics.traceId));
      expect(restored.generationSuccessful, equals(baseMetrics.generationSuccessful));
    });

    test('fromJson uses defaults for missing fields', () {
      final restored = GenerationMetrics.fromJson({'traceId': 'test'});
      expect(restored.requestedCount, equals(0));
      expect(restored.generationSuccessful, isFalse);
      expect(restored.traceId, equals('test'));
    });
  });
}
