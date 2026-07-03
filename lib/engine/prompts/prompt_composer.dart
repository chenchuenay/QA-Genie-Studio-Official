import 'dart:convert';

class PromptComposer {
  const PromptComposer();

  static String compose({
    required String module,
    required String feature,
    required String platform,
    required Map<String, int> categoryCounts,
    String? constraints,
    String domain = 'general',
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
      _buildContextBlock(
        module: module,
        feature: feature,
        platform: platform,
        constraints: constraints,
        domain: domain,
      ),
    );

    buffer.writeln(_buildPlanBlock(categoryCounts));

    return buffer.toString();
  }

  static String _buildContextBlock({
    required String module,
    required String feature,
    required String platform,
    required String domain,
    String? constraints,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('\n=== CONTEXT ===');
    buffer.writeln('DOMAIN: $domain');
    buffer.writeln('PLATFORM: $platform');
    buffer.writeln('MODULE: $module');
    buffer.writeln('FEATURE: $feature');
    if (constraints != null && constraints.trim().isNotEmpty) {
      buffer.writeln('CONSTRAINTS: ${constraints.trim()}');
    }
    return buffer.toString();
  }

  static const _defaultPriority = <String, String>{
    'positive': 'Low',
    'negative': 'Medium',
    'boundary': 'Medium',
    'validation': 'Medium',
    'security': 'High',
    'session': 'High',
  };

  static String _buildPlanBlock(Map<String, int> categoryCounts) {
    final total = categoryCounts.values.fold(0, (a, b) => a + b);
    final breakdown = categoryCounts.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');
    final priorityLine = categoryCounts.entries
        .map((e) => '${e.key}→${_defaultPriority[e.key] ?? "Medium"}')
        .join(', ');
    return '\n=== PLAN ===\nGenerate $total test cases with coverage: $breakdown\nDefault priority: $priorityLine\n';
  }
}
