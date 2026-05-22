import 'package:qa_genie/engine/models/generation_complexity_profile.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';

class RealismComplexityEstimator {
  static double estimate(GenerationComplexityProfile profile) {
    double complexity = 1.0;
    final ctx = '${profile.module} ${profile.feature}'.toLowerCase();

    // Workflow Complexity Multipliers
    if (['auth', 'login', 'session', 'otp'].any(ctx.contains)) complexity += 0.4;
    if (['payment', 'transaction', 'checkout', 'billing'].any(ctx.contains)) complexity += 0.7;
    if (['cart', 'order', 'inventory'].any(ctx.contains)) complexity += 0.3;

    // Platform Realism Multipliers
    if (profile.platform == 'API') {
      complexity += 0.6; // High cost for idempotency/concurrency realism
    } else if (profile.platform == 'Mobile') {
      complexity += 0.4; // App lifecycle/reconnect realism
    } else if (profile.platform == 'Web') {
      complexity += 0.3; // Refresh/tab/navigation realism
    }

    // Intent-based Multipliers
    for (final intent in profile.intents) {
      switch (intent) {
        case ExecutionIntent.retrySafety:
        case ExecutionIntent.interruptionRecovery:
        case ExecutionIntent.duplicateProtection:
          complexity += 0.15;
          break;
        case ExecutionIntent.sessionIsolation:
        case ExecutionIntent.stateIntegrity:
          complexity += 0.1;
          break;
        default:
          complexity += 0.05;
      }
    }

    // Temporal/Interruption depth
    if (profile.requestedCases > 5) {
      complexity += 0.2; // Headroom for diversity maintenance
    }

    return complexity;
  }
}
