import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/scenario/scenario_engine.dart';
import 'package:qa_genie/engine/planners/coverage_planner.dart';

/// Generates skeletons for AI prompt in the same format as old ScenarioPlanner.
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
    // Use CoveragePlanner and ScenarioEngine to produce assignments, then convert to old skeleton format
    final coveragePlanner = CoveragePlanner(
      mode: mode,
      totalCount: count,
      constraints: constraints,
      seed: '${module}|$feature|$platform|$domain|$constraints',
    );
    final coverage = coveragePlanner.plan();

    final businessArea = _inferBusinessArea();
    final scenarioEngine = ScenarioEngine(coveragePlanner.seed);
    final assignments = scenarioEngine.generateAssignments(
      categoryCounts: coverage.categoryCounts,
      businessArea: businessArea,
    );

    final skeletons = <Map<String, dynamic>>[];
    for (final assignment in assignments) {
      skeletons.add({
        'intent_id': assignment.outcome,
        'category': assignment.category,
        'priority': _priorityFromRisk(assignment.risk),
        'type': null,
        'module': module,
        'feature': feature,
        'platform': platform,
        'constraints': constraints,
        'title': _titleForOutcome(assignment.outcome, feature),
      });
    }
    return skeletons;
  }

  BusinessArea _inferBusinessArea() {
    final f = feature.toLowerCase();
    if (f.contains('login') || f.contains('auth') || f.contains('password')) {
      return const BusinessArea(
        id: 'authentication',
        domain: 'security',
        riskProfile: 'MEDIUM',
      );
    }
    if (f.contains('checkout') || f.contains('cart') || f.contains('order')) {
      return const BusinessArea(
        id: 'ecommerce',
        domain: 'transaction',
        riskProfile: 'HIGH',
      );
    }
    if (f.contains('transfer') || f.contains('payment') || f.contains('otp')) {
      return const BusinessArea(
        id: 'banking',
        domain: 'finance',
        riskProfile: 'HIGH',
      );
    }
    return const BusinessArea(
      id: 'general',
      domain: 'general',
      riskProfile: 'LOW',
    );
  }

  String _priorityFromRisk(String risk) {
    switch (risk) {
      case 'HIGH':
        return 'High';
      case 'MEDIUM':
        return 'Medium';
      default:
        return 'Low';
    }
  }

  String _titleForOutcome(String outcome, String feature) {
    // Simple mapping for prompt skeleton titles (not used for final test case titles)
    switch (outcome) {
      case 'valid_login':
        return 'User logs in with valid credentials';
      case 'social_login':
        return 'Social login with Google';
      case 'invalid_password':
        return 'Login fails with invalid password';
      default:
        return '$outcome test for $feature';
    }
  }
}
