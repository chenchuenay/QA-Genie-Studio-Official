import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/states.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/models/domain_context.dart';
import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/planners/domain_detector.dart';
import 'package:qa_genie/engine/models/scenario_assignment.dart';
import 'package:qa_genie/engine/scenarios/scenario_registry.dart';

class ScenarioEngine {
  final String seed;
  ScenarioEngine(this.seed);

  List<ScenarioAssignment> generateAssignments({
    required Map<String, int> categoryCounts,
    required BusinessArea businessArea,
  }) {
    // 1. Map business area to a domain context
    final domain = _domainFromBusinessArea(businessArea);
    if (domain == null) return [];

    // 2. Get all scenarios for that domain
    final allScenarios = ScenarioRegistry.getForDomain(domain);
    if (allScenarios.isEmpty) return [];

    // 3. Group scenarios by category
    final scenariosByCategory = <String, List<Scenario>>{};
    for (final scenario in allScenarios) {
      final cat = scenario.category;
      scenariosByCategory.putIfAbsent(cat, () => []).add(scenario);
    }

    // 4. Build assignments
    final assignments = <ScenarioAssignment>[];
    for (final entry in categoryCounts.entries) {
      final category = entry.key;
      final needed = entry.value;
      final available = scenariosByCategory[category] ?? [];
      if (available.isEmpty && needed > 0) {
        // Fallback: use positive scenarios (or generic)
        final positiveAvailable = scenariosByCategory['positive'] ?? [];
        if (positiveAvailable.isNotEmpty) {
          for (int i = 0; i < needed && assignments.length < needed; i++) {
            final scenario = positiveAvailable[i % positiveAvailable.length];
            assignments.add(
              ScenarioAssignment(scenario: scenario, index: assignments.length),
            );
          }
        } else {
          // Ultimate fallback: create a generic scenario
          final generic = Scenario(
            entity: EntityType.member,
            action: ActionType.login,
            targetState: StateType.active,
            category: category,
          );
          for (int i = 0; i < needed; i++) {
            assignments.add(
              ScenarioAssignment(scenario: generic, index: assignments.length),
            );
          }
        }
        continue;
      }
      for (int i = 0; i < needed && i < available.length; i++) {
        final scenario = available[i % available.length];
        assignments.add(
          ScenarioAssignment(scenario: scenario, index: assignments.length),
        );
      }
    }

    // 5. Ensure we have exactly the sum of categoryCounts
    final totalNeeded = categoryCounts.values.fold(0, (a, b) => a + b);
    if (assignments.length < totalNeeded && totalNeeded > 0) {
      final generic = Scenario(
        entity: EntityType.member,
        action: ActionType.login,
        targetState: StateType.active,
        category: 'positive',
      );
      while (assignments.length < totalNeeded) {
        assignments.add(
          ScenarioAssignment(scenario: generic, index: assignments.length),
        );
      }
    }

    return assignments.take(totalNeeded).toList();
  }

  DomainContext? _domainFromBusinessArea(BusinessArea businessArea) {
    final domainId = businessArea.domain.toLowerCase();
    final businessId = businessArea.id.toLowerCase();

    if (domainId.contains('security') ||
        businessId.contains('authentication')) {
      return DomainDetector.detect('auth', 'login');
    }
    if (domainId.contains('transaction') || businessId.contains('ecommerce')) {
      return DomainDetector.detect('cart', 'checkout');
    }
    if (domainId.contains('finance') || businessId.contains('banking')) {
      return DomainDetector.detect('payment', 'transfer');
    }
    if (businessId.contains('scheduling') ||
        businessId.contains('appointment')) {
      return DomainDetector.detect('appointment', 'booking');
    }
    if (businessId.contains('medical') || businessId.contains('record')) {
      return DomainDetector.detect('patient', 'record');
    }
    // Default fallback domain
    return DomainDetector.detect('general', 'feature');
  }
}
