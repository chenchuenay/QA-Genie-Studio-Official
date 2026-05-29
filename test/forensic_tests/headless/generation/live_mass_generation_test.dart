import 'dart:async';
import '../../support/live_http.dart';
import '../../support/forensic_runner.dart';
import '../../inputs/generation_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ensureLiveNetworking();
  test(
    'Mass generation across all platforms',
    () async {
      for (final platform in GenerationInputs.platforms) {
        await ForensicRunner.execute(
          module: GenerationInputs.module,
          feature: GenerationInputs.feature,
          constraints: GenerationInputs.constraints,
          platform: platform,
          isPro: GenerationInputs.isPro,
        );
        await Future.delayed(GenerationInputs.cooldownBetweenPlatforms);
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
