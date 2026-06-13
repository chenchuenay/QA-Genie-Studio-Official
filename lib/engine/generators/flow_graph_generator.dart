import '../ontology/domain_registry.dart';

class FlowGraphGenerator {
  static List<Map<String, String>> generate(
    String domain,
    String action,
    String platform,
    String constraints,
  ) {
    final pattern = DomainRegistry.ontology[domain]?[action];
    if (pattern == null) {
      return [{'action': 'Execute fallback action', 'data': 'N/A', 'expected': 'Success'}];
    }

    // Constraint filtering
    final constraintList = constraints.split(',').map((s) => s.trim()).toList();
    for (final req in pattern.requiredConstraints) {
      if (!constraintList.contains(req)) {
        return [{'action': 'Skip action', 'data': 'Constraints not met: $req', 'expected': 'Action skipped'}];
      }
    }

    final steps = <Map<String, String>>[];
    final actionSteps = pattern.stepsByPlatform[platform] ?? pattern.stepsByPlatform.values.first;

    for (final step in actionSteps) {
      steps.add({
        'action': step,
        'data': 'Dynamic Data from Ontology',
        'expected': 'Verify ${step.split(RegExp(r'(?=[A-Z])')).join(' ')} completed'
      });
    }

    return steps;
  }
}
