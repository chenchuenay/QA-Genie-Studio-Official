import 'dart:math';
import 'generation_mode.dart';
import 'qa_heuristics_engine.dart';
import '../core/utils/template_registry.dart';

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

  List<String> _weightedDefaultCategories() {
    final weighted = <String>[
      // -------------------------
      // PRIMARY USER EXPERIENCE
      // -------------------------
      'positive',
      'positive',
      'positive',
      'positive',
      // -------------------------
      // NORMAL QA NEGATIVE CASES
      // -------------------------
      'negative',
      'validation',
      // -------------------------
      // OCCASIONAL SECONDARY
      // -------------------------
      'boundary',
      'usability',
      // -------------------------
      // RARE WITHOUT CONSTRAINTS
      // -------------------------
      'session',
      'security',
    ];
    weighted.shuffle(_random);
    return weighted;
  }

  List<Map<String, dynamic>> generateSkeletons() {
    final templates =
        TemplateRegistry.platformTemplates[platform] ??
        TemplateRegistry.platformTemplates['Web']!;
    final skeletons = <Map<String, dynamic>>[];
    final usedTitles = <String>{};
    final categories = _weightedDefaultCategories();

    for (final category in categories) {
      if (skeletons.length >= count) {
        break;
      }
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
      if (scenarios.isEmpty) {
        scenarios = [_syntheticScenario(category)];
      }
      scenarios.shuffle(_random);

      for (final rawScenario in scenarios) {
        if (skeletons.length >= count) {
          break;
        }
        final scenario = _compressScenarioTitle(rawScenario);
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
        // Break inner loop to ensure we pick from different categories if possible,
        // but since categories are weighted and shuffled, we will likely get more POSITIVEs.
        break;
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

      final scenario = _compressScenarioTitle(
        scenarios.isNotEmpty
            ? scenarios[guard % scenarios.length]
            : _syntheticScenario(category),
      );

      final uniqueScenario = '$scenario alt ${guard + 1}';

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

  String _compressScenarioTitle(String title) {
    var text = title.trim();

    const replacements = {
      'Verify successful login with valid credentials': 'Valid login succeeds',
      'Verify login failure with incorrect password':
          'Invalid password rejected',
      'Verify session persists after page refresh': 'Session survives refresh',
      'Verify login form is protected against SQL injection':
          'SQL injection blocked',
      'Verify login form is protected against XSS attacks': 'XSS blocked',
      'Verify session token is invalidated after logout':
          'Logout clears session',
      'Verify email field handles maximum character length':
          'Email max length enforced',
      'Verify password field enforces maximum character length':
          'Password max length enforced',
      'Verify required field validation messages are displayed':
          'Required fields validated',
      'Verify email format validation rejects invalid addresses':
          'Invalid email rejected',
      'Verify form submission is blocked with missing fields':
          'Missing fields blocked',
      'Verify session expires after inactivity timeout': 'Idle session expires',
      'Verify concurrent sessions prevent session leakage':
          'Sessions stay isolated',
    };

    text = replacements[text] ?? text;
    text = text
        .replaceFirst(RegExp(r'^Verify\s+', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\bis protected against\b', caseSensitive: false),
          'blocks',
        )
        .replaceAll(
          RegExp(r'\bfailure with\b', caseSensitive: false),
          'rejects',
        )
        .replaceAll(RegExp(r'\bsuccessful\b', caseSensitive: false), 'valid')
        .replaceAll(
          RegExp(r'\bmessages are displayed\b', caseSensitive: false),
          'shown',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (text.length <= 45) return text;

    final words = text.split(' ');
    final compact = StringBuffer();
    for (final word in words) {
      final next = compact.isEmpty ? word : '${compact.toString()} $word';
      if (next.length > 45) break;
      compact
        ..clear()
        ..write(next);
    }

    return compact.isEmpty ? text.substring(0, 45).trim() : compact.toString();
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
        return 'Verify $feature handles a representative user workflow with clear observable outcomes';
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
