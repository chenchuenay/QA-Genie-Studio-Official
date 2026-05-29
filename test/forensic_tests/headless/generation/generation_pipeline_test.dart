import '../../support/forensic_runner.dart';
import '../../inputs/generation_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Single generation', () async {
    final platform = GenerationInputs.platforms[GenerationInputs.platformIndex];
    await ForensicRunner.execute(
      module: GenerationInputs.module,
      feature: GenerationInputs.feature,
      constraints: GenerationInputs.constraints,
      platform: platform,
      isPro: GenerationInputs.isPro,
    );
  });
}
