import 'package:qa_genie/domain/enums/execution_intent.dart';

class GenerationComplexityProfile {
  final String module;
  final String feature;
  final String platform;
  final int requestedCases;
  final bool isPro;
  final List<ExecutionIntent> intents;
  final int avgStepDepth;

  GenerationComplexityProfile({
    required this.module,
    required this.feature,
    required this.platform,
    required this.requestedCases,
    required this.isPro,
    this.intents = const [],
    this.avgStepDepth = 4,
  });
}
