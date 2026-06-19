import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/case_source.dart';

void main() {
  group('CaseSource', () {
    test('ai has correct value', () {
      expect(CaseSource.ai.value, 'AI');
    });

    test('fallback has correct value', () {
      expect(CaseSource.fallback.value, 'Fallback');
    });

    test('repaired and repairedAi both map to Repaired', () {
      expect(CaseSource.repaired.value, 'Repaired');
      expect(CaseSource.repairedAi.value, 'Repaired');
    });

    test('emergency has correct value', () {
      expect(CaseSource.emergency.value, 'Emergency');
    });

    test('imported has correct value', () {
      expect(CaseSource.imported.value, 'Imported');
    });

    test('manual has correct value', () {
      expect(CaseSource.manual.value, 'Manual');
    });
  });

  group('isAiGenerated', () {
    test('returns true for ai', () {
      expect(CaseSource.ai.isAiGenerated, true);
    });

    test('returns true for fallback', () {
      expect(CaseSource.fallback.isAiGenerated, true);
    });

    test('returns true for repaired', () {
      expect(CaseSource.repaired.isAiGenerated, true);
    });

    test('returns true for repairedAi', () {
      expect(CaseSource.repairedAi.isAiGenerated, true);
    });

    test('returns true for emergency', () {
      expect(CaseSource.emergency.isAiGenerated, true);
    });

    test('returns false for imported', () {
      expect(CaseSource.imported.isAiGenerated, false);
    });

    test('returns false for manual', () {
      expect(CaseSource.manual.isAiGenerated, false);
    });
  });

  group('isRecoverySource', () {
    test('returns false for ai', () {
      expect(CaseSource.ai.isRecoverySource, false);
    });

    test('returns true for fallback', () {
      expect(CaseSource.fallback.isRecoverySource, true);
    });

    test('returns true for repaired', () {
      expect(CaseSource.repaired.isRecoverySource, true);
    });

    test('returns true for repairedAi', () {
      expect(CaseSource.repairedAi.isRecoverySource, true);
    });

    test('returns true for emergency', () {
      expect(CaseSource.emergency.isRecoverySource, true);
    });

    test('returns false for imported', () {
      expect(CaseSource.imported.isRecoverySource, false);
    });

    test('returns false for manual', () {
      expect(CaseSource.manual.isRecoverySource, false);
    });
  });
}
