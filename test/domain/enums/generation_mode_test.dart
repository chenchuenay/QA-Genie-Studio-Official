import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/app/config/app_config.dart';

void main() {
  group('GenerationMode', () {
    test('core and pro both exist', () {
      expect(GenerationMode.values.length, 2);
      expect(GenerationMode.core, isNotNull);
      expect(GenerationMode.pro, isNotNull);
    });
  });

  group('testCaseCount', () {
    test('core returns from AppConfig', () {
      expect(GenerationMode.core.testCaseCount, AppConfig.coreCasesPerBatch);
    });

    test('pro returns from AppConfig', () {
      expect(GenerationMode.pro.testCaseCount, AppConfig.proCasesPerBatch);
    });
  });

  group('exportLimit', () {
    test('core has limit of 50', () {
      expect(GenerationMode.core.exportLimit, 50);
    });

    test('pro is unlimited (-1)', () {
      expect(GenerationMode.pro.exportLimit, -1);
    });
  });

  group('summaryExportLimit', () {
    test('core has limit of 50', () {
      expect(GenerationMode.core.summaryExportLimit, 50);
    });

    test('pro is unlimited (-1)', () {
      expect(GenerationMode.pro.summaryExportLimit, -1);
    });
  });

  group('isUnlimited', () {
    test('pro is unlimited', () {
      expect(GenerationMode.pro.isUnlimited, true);
    });

    test('core is not unlimited', () {
      expect(GenerationMode.core.isUnlimited, false);
    });
  });

  group('requiresAds', () {
    test('core requires ads', () {
      expect(GenerationMode.core.requiresAds, true);
    });

    test('pro does not require ads', () {
      expect(GenerationMode.pro.requiresAds, false);
    });
  });

  group('displayName', () {
    test('core display name', () {
      expect(GenerationMode.core.displayName, 'CORE');
    });

    test('pro display name', () {
      expect(GenerationMode.pro.displayName, 'PRO');
    });
  });

  group('ratios', () {
    test('happyPathRatio is 0.8 for both', () {
      expect(GenerationMode.core.happyPathRatio, 0.8);
      expect(GenerationMode.pro.happyPathRatio, 0.8);
    });

    test('negativePathRatio is 0.2 for both', () {
      expect(GenerationMode.core.negativePathRatio, 0.2);
      expect(GenerationMode.pro.negativePathRatio, 0.2);
    });
  });
}
