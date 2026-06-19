import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/app/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('coreFreeBatchesPerDay is 0', () {
      expect(AppConfig.coreFreeBatchesPerDay, 0);
    });

    test('coreRewardedBatchesPerDay is 6', () {
      expect(AppConfig.coreRewardedBatchesPerDay, 6);
    });

    test('proFreeBatchesPerDay is 15', () {
      expect(AppConfig.proFreeBatchesPerDay, 15);
    });

    test('coreCasesPerBatch is 10', () {
      expect(AppConfig.coreCasesPerBatch, 10);
    });

    test('proCasesPerBatch is 20', () {
      expect(AppConfig.proCasesPerBatch, 20);
    });

    test('coreDailyExportLimit is 50', () {
      expect(AppConfig.coreDailyExportLimit, 50);
    });

    test('proMonthlyPrice is \$6.99', () {
      expect(AppConfig.proMonthlyPrice, '\$6.99');
    });

    test('maxConstraintsLength is 100', () {
      expect(AppConfig.maxConstraintsLength, 100);
    });

    test('rewardedTcGenerationAdUnit is test ad unit', () {
      expect(AppConfig.rewardedTcGenerationAdUnit, 'ca-app-pub-3940256099942544/5224354917');
    });

    test('initTestProMode sets testProMode', () {
      AppConfig.initTestProMode(true);
      expect(AppConfig.testProMode, isTrue);
      AppConfig.initTestProMode(false);
    });

    test('allowDebugTools is true in dev', () {
      expect(AppConfig.allowDebugTools, isTrue);
    });
  });
}
