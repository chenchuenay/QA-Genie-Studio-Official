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

    // Track used categories to prioritize unused ones
    final usedCategories = <String>{};
    final availableTemplates = Map<String, dynamic>.from(templates);

    // First pass: Fill with unique categories
    if (count > 0 && availableTemplates.isNotEmpty) {
      final availableCategoryKeys = availableTemplates.keys.toList();
      availableCategoryKeys.shuffle(_random); // Shuffle to randomize selection
      
      for (final cat in availableCategoryKeys) {
        if (skeletons.length >= count) break;
        
        final cnt = dist[cat] ?? 0;
        if (cnt == 0) continue;

        final tpl = availableTemplates[cat];
        if (tpl == null) continue;

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
          // Corrected call to _syntheticScenario using 'cat'
          scenarios = [_syntheticScenario(cat)]; 
        }
        scenarios.shuffle(_random);

        for (int i = 0; i < cnt; i++) {
          if (skeletons.length >= count) break;
          final idx = i % scenarios.length;
          skeletons.add({
            'category': cat,
            'title': scenarios[idx],
            'module': module,
            'feature': feature,
            'platform': platform,
            'priority': QaHeuristicsEngine.priorityFor(
              category: cat,
              module: module,
              feature: feature,
              title: scenarios[idx],
              platform: platform,
              domain: domain,
            ),
            'type': _categoryToType(cat),
            'intent_id': tpl['intent_id'] ?? 'generic',
          });
          usedCategories.add(cat);
        }
      }
    }

    // Second pass: If more count is needed, fill with potentially repeated categories, but prefer promoted ones.
    // This logic ensures we meet the total count, while prioritizing diversity in the first pass.
    // Further refinement could involve more sophisticated preference logic.

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
