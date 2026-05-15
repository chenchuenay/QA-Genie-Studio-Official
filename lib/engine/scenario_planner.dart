import 'dart:math';
import 'generation_mode.dart';
import 'template_registry.dart';
import 'distribution_engine.dart';
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

  static int _generateSeed(
    String module,
    String feature,
    String platform,
    String domain,
  ) {
    return '$module|$feature|$platform|$domain'.hashCode;
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

    final distribution = engine.calculate();

    final templates =
        TemplateRegistry.platformTemplates[platform] ??
        TemplateRegistry.platformTemplates['Web']!;

    final skeletons = <Map<String, dynamic>>[];

    final usedTitles = <String>{};

    final categories = templates.keys.toList()..shuffle(_random);

    // PASS 1: Try category-balanced generation first
    for (final category in categories) {
      if (skeletons.length >= count) {
        break;
      }

      final template = templates[category];

      if (template == null) {
        continue;
      }

      final requiredCount = distribution[category] ?? 0;

      if (requiredCount <= 0) {
        continue;
      }

      List<String> scenarios = List<String>.from(
        template['scenarios'] ?? const [],
      );

      scenarios = scenarios
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

      for (int i = 0; i < requiredCount; i++) {
        if (skeletons.length >= count) {
          break;
        }

        final scenario = scenarios[i % scenarios.length];
        final normalizedTitle = scenario.toLowerCase().trim();

        if (usedTitles.contains(normalizedTitle)) {
          continue;
        }

        usedTitles.add(normalizedTitle);

        skeletons.add(
          _buildSkeleton(
            category: category,
            title: scenario,
            intentId: template['intent_id'] ?? 'generic',
          ),
        );
      }
    }

    // PASS 2: Fill remaining gaps deterministically
    int guard = 0;

    while (skeletons.length < count && guard < count * 5) {
      guard++;

      final category = categories[guard % categories.length];

      final template = templates[category];

      if (template == null) {
        continue;
      }

      List<String> scenarios = List<String>.from(
        template['scenarios'] ?? const [],
      );

      scenarios = scenarios
          .where(
            (scenario) => QaHeuristicsEngine.scenarioMatchesContext(
              scenario,
              module,
              feature,
              domain,
            ),
          )
          .toList();

      final scenario = scenarios.isNotEmpty
          ? scenarios[guard % scenarios.length]
          : _syntheticScenario(category);

      final uniqueScenario = '$scenario - Variant ${guard + 1}';

      final normalizedTitle = uniqueScenario.toLowerCase().trim();

      if (usedTitles.contains(normalizedTitle)) {
        continue;
      }

      usedTitles.add(normalizedTitle);

      skeletons.add(
        _buildSkeleton(
          category: category,
          title: uniqueScenario,
          intentId: template['intent_id'] ?? 'generic',
        ),
      );
    }

    return skeletons.take(count).toList();
  }

  Map<String, dynamic> _buildSkeleton({
    required String category,
    required String title,
    required String intentId,
  }) {
    return {
      'category': category,
      'title': title,
      'module': module,
      'feature': feature,
      'platform': platform,
      'priority': QaHeuristicsEngine.priorityFor(
        category: category,
        module: module,
        feature: feature,
        title: title,
        platform: platform,
        domain: domain,
      ),
      'type': _categoryToType(category),
      'intent_id': intentId,
    };
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

  String _categoryToType(String category) {
    switch (category) {
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
