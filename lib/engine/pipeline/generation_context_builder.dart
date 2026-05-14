import 'package:qa_genie/engine/generation_mode.dart';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/scenario_planner.dart';
import 'package:qa_genie/engine/qa_heuristics_engine.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';
import 'package:qa_genie/engine/pipeline/pipeline_config.dart';

class GenerationContextBuilder {
  GenerationContext build({
    required String module,
    required String feature,
    required String platform,
    required String? notes,
    required int startIndex,
    required int requestedCount,
    PipelineConfig config = PipelineConfig.production,
  }) {
    final mode = parseConstraints(notes);
    final inferredDomain = QaHeuristicsEngine.inferDomain(
      module,
      feature,
      'general',
    );
    final planner = ScenarioPlanner(
      module: module,
      feature: feature,
      platform: platform,
      mode: mode,
      count: requestedCount,
      domain: inferredDomain,
    );
    final skeletons = planner.generateSkeletons();
    
    // Deterministic seed generation based on input context
    final seedString = '$module|$feature|$platform|$requestedCount|${notes ?? ''}';
    final seed = StableHash.forText(seedString, 1000000000);
    final deterministicSeed = seed.toString();

    final sessionId = 'GS-${DateTime.now().millisecondsSinceEpoch}-$seed';

    final context = GenerationContext(
      generationSessionId: sessionId,
      module: module,
      feature: feature,
      platform: platform,
      inferredDomain: inferredDomain,
      startIndex: startIndex,
      requestedCount: requestedCount,
      deterministicSeed: deterministicSeed,
      skeletons: skeletons,
      config: config,
    );

    context.promptMetadata['mode'] = mode.toString();
    context.promptMetadata['promptVersion'] = 'v1.4.0';
    context.promptMetadata['scenarioCount'] = skeletons.length;
    context.promptMetadata['notes'] = notes ?? '';
    context.promptMetadata['seed'] = deterministicSeed;

    final extractor = SemanticSignalExtractor();
    context.semanticSignals.addAll(extractor.extractSignals(module, feature, platform));
    context.detectedCategories.addAll(extractor.extractCategories(module, feature));
    
    return context;
  }
}

class SemanticSignalExtractor {
  static final RegExp _validationPattern = RegExp(r'validation|invalid|required|format|schema|field|error|message', caseSensitive: false);
  static final RegExp _securityPattern = RegExp(r'security|xss|csrf|injection|access|permission|authorize|unauthorized', caseSensitive: false);
  static final RegExp _sessionPattern = RegExp(r'session|expired|timeout|refresh|reconnect|persist|background', caseSensitive: false);

  Set<String> extractSignals(String module, String feature, String platform) {
    final text = '$module $feature $platform';
    final signals = <String>{};
    if (_validationPattern.hasMatch(text)) signals.add('validation');
    if (_securityPattern.hasMatch(text)) signals.add('security');
    if (_sessionPattern.hasMatch(text)) signals.add('session');
    return signals;
  }

  Set<String> extractCategories(String module, String feature) {
    final categories = <String>{};
    final text = '$module $feature';
    if (_securityPattern.hasMatch(text)) categories.add('SECURITY');
    if (_validationPattern.hasMatch(text)) categories.add('VALIDATION');
    if (categories.isEmpty) categories.add('FUNCTIONAL');
    return categories;
  }
}
