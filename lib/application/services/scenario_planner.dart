import 'dart:math';
import 'distribution_engine.dart';
import 'template_registry.dart';
import 'generation_mode.dart';
import 'qa_heuristics_engine.dart';

class ScenarioPlanner {
  final String module;
  final String feature;
  final String platform;
  final GenerationMode mode;
  final int count;
  final String domain;
  final Random _random;

  ScenarioPlanner({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    this.domain = 'general',
    int? seed,
  }) : _random = Random(
         seed ?? _generateSeed(module, feature, platform, domain),
       );

  static int _generateSeed(String m, String f, String p, String d) {
    return '$m|$f|$p|$d'.hashCode;
  }

  Random get random => _random;
  String get stableSeed => '$module|$feature|$platform|$domain';

  List<Map<String, dynamic>> generateSkeletons() {
    final engine = DistributionEngine(
      module: module,
      feature: feature,
      platform: platform,
      mode: mode,
      count: count,
      domain: domain,
    );
    final dist = engine.calculate();
    final templates =
        TemplateRegistry.platformTemplates[platform] ??
        TemplateRegistry.platformTemplates['Web']!;
    final skeletons = <Map<String, dynamic>>[];

    dist.forEach((category, cnt) {
      final tpl = templates[category];
      if (tpl == null) return;
      var scenarios = List<String>.from(tpl['scenarios'])
          .where(
            (scenario) => QaHeuristicsEngine.scenarioMatchesContext(
              scenario,
              module,
              feature,
              domain,
            ),
          )
          .toList();
      if (scenarios.isEmpty) {
        scenarios = [_syntheticScenario(category)];
      }
      scenarios.shuffle(_random);
      for (int i = 0; i < cnt; i++) {
        final idx = i % scenarios.length;
        skeletons.add({
          'category': category,
          'title': scenarios[idx],
          'module': module,
          'feature': feature,
          'platform': platform,
          'priority': QaHeuristicsEngine.priorityFor(
            category: category,
            module: module,
            feature: feature,
            title: scenarios[idx],
            platform: platform,
            domain: domain,
          ),
          'type': _categoryToType(category),
          'intent_id': tpl['intent_id'] ?? 'generic',
        });
      }
    });
    return skeletons.take(count).toList();
  }

  String _syntheticScenario(String category) {
    switch (category) {
      case 'positive':
        return 'Verify successful $feature flow with valid inputs';
      case 'negative':
        return 'Verify $feature rejects invalid input with clear validation feedback';
      case 'security':
        return 'Verify $feature blocks unauthorized or tampered requests';
      case 'boundary':
        return 'Verify $feature enforces input and payload boundary limits';
      case 'validation':
        return 'Verify $feature validates required fields and formats';
      case 'session':
        return 'Verify $feature maintains correct session lifecycle behavior';
      case 'usability':
        return 'Verify $feature remains accessible and clear during repeated use';
      default:
        return 'Verify $feature default workflow stability';
    }
  }

  String _categoryToType(String cat) {
    switch (cat) {
      case 'positive':
        return 'POSITIVE';
      case 'negative':
        return 'NEGATIVE';
      case 'security':
        return 'SECURITY';
      case 'boundary':
        return 'EDGE';
      case 'validation':
        return 'VALIDATION';
      case 'session':
        return 'SESSION';
      case 'usability':
        return 'USABILITY';
      default:
        return 'GENERAL';
    }
  }
}
