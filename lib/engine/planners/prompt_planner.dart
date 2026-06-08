import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/planners/coverage_planner.dart';

/// Generates deterministic coverage skeletons for the AI prompt.
class PromptPlanner {
  final String module;
  final String feature;
  final String platform;
  final GenerationMode mode;
  final int count;
  final String domain;
  final String constraints;

  PromptPlanner({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    this.domain = 'general',
    this.constraints = '',
  });

  List<Map<String, dynamic>> generateSkeletons() {
    final coveragePlanner = CoveragePlanner(
      mode: mode,
      totalCount: count,
      constraints: constraints,
      seed: '${module}|$feature|$platform|$domain|$constraints',
    );
    final coverage = coveragePlanner.plan();

    final skeletons = <Map<String, dynamic>>[];
    for (final entry in coverage.categoryCounts.entries) {
      final category = entry.key;
      final needed = entry.value;
      for (int i = 0; i < needed; i++) {
        // Create a unique intent per category
        final intentId = '${category}_${i + 1}';
        skeletons.add({
          'intent_id': intentId,
          'category': category,
          'priority': _priorityForCategory(category),
          'type': category.toUpperCase(),
          'module': module,
          'feature': feature,
          'platform': platform,
          'constraints': constraints,
          'title': _titleForCategory(category, feature),
        });
      }
    }
    return skeletons;
  }

  String _priorityForCategory(String category) {
    switch (category) {
      case 'security':
      case 'session':
        return 'High';
      case 'negative':
      case 'validation':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _titleForCategory(String category, String feature) {
    switch (category) {
      case 'positive':
        return '$feature - positive scenario';
      case 'negative':
        return '$feature - negative scenario';
      case 'boundary':
        return '$feature - boundary test';
      case 'security':
        return '$feature - security test';
      case 'validation':
        return '$feature - validation test';
      default:
        return '$feature test';
    }
  }
}
