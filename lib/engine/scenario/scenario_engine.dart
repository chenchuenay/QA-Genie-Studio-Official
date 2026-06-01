import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/scenario/scenario_rules.dart';

class ScenarioAssignment {
  final BusinessArea businessArea;
  final String outcome;
  final String category;
  final String risk;

  const ScenarioAssignment({
    required this.businessArea,
    required this.outcome,
    required this.category,
    required this.risk,
  });
}

class ScenarioEngine {
  final String seed;
  final Set<String> _usedKeys = {};

  ScenarioEngine(this.seed);

  List<ScenarioAssignment> generateAssignments({
    required Map<String, int> categoryCounts,
    required BusinessArea businessArea,
  }) {
    final assignments = <ScenarioAssignment>[];
    for (final entry in categoryCounts.entries) {
      final category = entry.key;
      final count = entry.value;
      final possibleOutcomes = ScenarioRules.getOutcomes(
        businessArea,
        category,
      );
      if (possibleOutcomes.isEmpty) continue;

      // Deterministic order based on seed
      final ordered = _deterministicOrder(possibleOutcomes, '$seed|$category');

      for (int i = 0; i < count; i++) {
        final outcome = _pickUnused(ordered, businessArea.id, category);
        assignments.add(
          ScenarioAssignment(
            businessArea: businessArea,
            outcome: outcome,
            category: category,
            risk: _riskForCategory(category),
          ),
        );
      }
    }
    return assignments;
  }

  List<String> _deterministicOrder(List<String> outcomes, String key) {
    final indexed = outcomes.asMap().entries.toList();
    indexed.sort((a, b) {
      final ha = StableHash.forText('$key|${a.value}', 9999);
      final hb = StableHash.forText('$key|${b.value}', 9999);
      return ha.compareTo(hb);
    });
    return indexed.map((e) => e.value).toList();
  }

  String _pickUnused(
    List<String> ordered,
    String businessAreaId,
    String category,
  ) {
    for (final outcome in ordered) {
      final key = '$businessAreaId:$category:$outcome';
      if (!_usedKeys.contains(key)) {
        _usedKeys.add(key);
        return outcome;
      }
    }
    // All used – pick first (allow repeat, but we log later)
    final fallback = ordered.first;
    final fallbackKey = '$businessAreaId:$category:$fallback';
    _usedKeys.add(fallbackKey);
    return fallback;
  }

  String _riskForCategory(String category) {
    switch (category) {
      case 'security':
      case 'session':
        return 'HIGH';
      case 'negative':
        return 'MEDIUM';
      default:
        return 'LOW';
    }
  }
}
