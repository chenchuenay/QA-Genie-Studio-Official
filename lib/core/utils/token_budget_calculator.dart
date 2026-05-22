import 'realism_complexity_estimator.dart';
import 'package:qa_genie/engine/models/generation_complexity_profile.dart';

class TokenBudgetCalculator {
  static int calculate(GenerationComplexityProfile profile) {
    // Base allowance for non-case structural tokens
    final int base = profile.isPro ? 1200 : 800;
    
    // Per-case token allocation (includes depth headroom)
    final int caseAllocation = 300;
    
    final double complexity = RealismComplexityEstimator.estimate(profile);

    final double rawBudget = (base + (profile.requestedCases * caseAllocation)) * complexity;
    
    // Final clamping to ensure valid API limits
    return rawBudget.toInt().clamp(1800, 8192);
  }
}
