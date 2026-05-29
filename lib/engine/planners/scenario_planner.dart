import 'dart:math';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

// ============================================================
// FILE: lib/engine/planners/scenario_planner.dart
// ============================================================

class ScenarioPlanner {
  final String module;
  final String feature;
  final String platform;
  final GenerationMode mode;
  final int count;
  final String domain;
  final String constraints;

  final Random _random;

  ScenarioPlanner({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    this.domain = 'general',
    this.constraints = '',
    int? seed,
  }) : _random = Random(
         seed ?? _generateSeed(module, feature, platform, domain, constraints),
       );

  static int _generateSeed(
    String module,
    String feature,
    String platform,
    String domain,
    String constraints,
  ) {
    return StableHash.forText(
      '$module|$feature|$platform|$domain|$constraints',
      99999999,
    );
  }

  Random get random => _random;

  String get stableSeed => '$module|$feature|$platform|$domain|$constraints';

  bool get _securityFocused {
    final c = constraints.toLowerCase();

    return c.contains('security') ||
        c.contains('sql') ||
        c.contains('xss') ||
        c.contains('token') ||
        c.contains('auth') ||
        c.contains('unauthorized') ||
        c.contains('csrf');
  }

  bool get _negativeFocused {
    final c = constraints.toLowerCase();

    return c.contains('negative') ||
        c.contains('invalid') ||
        c.contains('boundary') ||
        c.contains('edge') ||
        c.contains('validation');
  }

  bool get _sessionFocused {
    final c = constraints.toLowerCase();

    return c.contains('session') ||
        c.contains('timeout') ||
        c.contains('expiry') ||
        c.contains('logout');
  }

  List<String> _buildCategoryPlan() {
    final categories = <String>[];

    int happyCount = (count * 0.8).round();

    // =========================================================
    // CONSTRAINT OVERRIDES
    // =========================================================

    if (_securityFocused) {
      happyCount = (count * 0.3).round();
    } else if (_negativeFocused) {
      happyCount = (count * 0.5).round();
    } else if (_sessionFocused) {
      happyCount = (count * 0.6).round();
    }

    // =========================================================
    // HAPPY PATHS
    // =========================================================

    for (int i = 0; i < happyCount; i++) {
      categories.add('positive');
    }

    // =========================================================
    // NEGATIVE DISTRIBUTION
    // =========================================================

    while (categories.length < count) {
      if (_securityFocused) {
        categories.addAll(['security', 'negative', 'validation']);
      } else if (_sessionFocused) {
        categories.addAll(['session', 'negative']);
      } else {
        categories.addAll(['negative', 'validation', 'boundary']);
      }
    }

    categories.shuffle(_random);

    return categories.take(count).toList();
  }

  List<Map<String, dynamic>> generateSkeletons() {
    final skeletons = <Map<String, dynamic>>[];

    final usedTitles = <String>{};

    final plannedCategories = _buildCategoryPlan();

    int guard = 0;

    while (skeletons.length < count && guard < count * 20) {
      guard++;

      final category = plannedCategories[guard % plannedCategories.length];

      final scenario = _scenarioFor(category);

      final normalized = scenario.toLowerCase().trim();

      if (usedTitles.contains(normalized)) {
        continue;
      }

      usedTitles.add(normalized);

      skeletons.add(
        _buildSkeleton(
          category: category,
          title: scenario,
          intentId: _intentId(category),
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
      'priority': _priorityFor(category),
      'type': _categoryToType(category),
      'intent_id': intentId,
    };
  }

  String _priorityFor(String category) {
    switch (category) {
      case 'security':
        return 'Critical';

      case 'session':
        return 'High';

      case 'negative':
        return 'High';

      case 'validation':
        return 'Medium';

      case 'boundary':
        return 'Medium';

      default:
        return 'Low';
    }
  }

  String _intentId(String category) {
    switch (category) {
      case 'positive':
        return 'positive_flow';

      case 'negative':
        return 'negative_flow';

      case 'validation':
        return 'validation_flow';

      case 'boundary':
        return 'boundary_flow';

      case 'security':
        return 'security_flow';

      case 'session':
        return 'session_flow';

      case 'usability':
        return 'usability_flow';

      default:
        return 'generic_flow';
    }
  }

  String _scenarioFor(String category) {
    switch (category) {
      case 'positive':
        return _positiveScenario();

      case 'negative':
        return _negativeScenario();

      case 'validation':
        return _validationScenario();

      case 'boundary':
        return _boundaryScenario();

      case 'security':
        return _securityScenario();

      case 'session':
        return _sessionScenario();

      case 'usability':
        return _usabilityScenario();

      default:
        return 'Verify $feature workflow behavior';
    }
  }

  String _positiveScenario() {
    final variants = [
      'Successful $feature flow using valid inputs',
      'User completes $feature workflow successfully',
      'Stable $feature operation under normal usage',
      'Correct application state after $feature',
    ];

    return _pick(variants);
  }

  String _negativeScenario() {
    final variants = [
      'Invalid $feature input rejection',
      'Malformed request handling during $feature',
      'Incorrect user input handling in $feature',
      'Failure handling during unsuccessful $feature',
    ];

    return _pick(variants);
  }

  String _validationScenario() {
    final variants = [
      'Required field validation in $feature',
      'Input format validation during $feature',
      'Empty field restriction handling',
      'Validation message accuracy in $feature',
    ];

    return _pick(variants);
  }

  String _boundaryScenario() {
    final variants = [
      'Maximum input length handling',
      'Boundary value processing in $feature',
      'Oversized payload rejection',
      'Edge-case behavior validation',
    ];

    return _pick(variants);
  }

  String _securityScenario() {
    final variants = [
      'SQL injection prevention in $feature',
      'Unauthorized access blocking',
      'Sensitive data protection validation',
      'Cross-site scripting prevention during $feature',
    ];

    return _pick(variants);
  }

  String _sessionScenario() {
    final variants = [
      'Session timeout handling',
      'Expired session validation',
      'Logout invalidates active session',
      'Session isolation between users',
    ];

    return _pick(variants);
  }

  String _usabilityScenario() {
    final variants = [
      'Workflow clarity during $feature',
      'Repeated usage stability',
      'Responsive interface behavior',
      'Smooth user interaction during $feature',
    ];

    return _pick(variants);
  }

  String _pick(List<String> variants) {
    final index = StableHash.forText(
      '$stableSeed|${variants.join()}',
      variants.length,
    );

    return _compressScenarioTitle(variants[index]);
  }

  String _compressScenarioTitle(String title) {
    var text = title.trim();

    text = text.replaceAll(RegExp(r'\s+'), ' ');

    if (text.length <= 60) {
      return text;
    }

    return text.substring(0, 60).trim();
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
