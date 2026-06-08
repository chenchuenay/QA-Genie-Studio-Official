import 'package:flutter_test/flutter_test.dart';
import '../headless/inputs/generation_inputs.dart';
import '../support/production_forensic_runner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  print('BINDINGS_READY');

  test('Production generation through Cloud Functions', () async {
    final platform = GenerationInputs.platforms[GenerationInputs.platformIndex];

    await ProductionForensicRunner.execute(
      module: GenerationInputs.module,
      feature: GenerationInputs.feature,
      constraints: GenerationInputs.constraints,
      platform: platform,
      isPro: GenerationInputs.isPro,
    );
  });
}
