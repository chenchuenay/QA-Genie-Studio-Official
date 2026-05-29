import 'dart:convert';
import 'package:qa_genie/engine/prompts/system_prompt.dart';
// ============================================================

// FILE: lib/engine/prompts/prompt_composer.dart

// ============================================================

class PromptComposer {
  const PromptComposer();

  // ==========================================================

  // PUBLIC ENTRY

  // ==========================================================

  static String compose({
    required String module,

    required String feature,

    required String platform,

    required List<Map<String, dynamic>> skeletons,

    String? constraints,

    String domain = 'general',
  }) {
    final buffer = StringBuffer();

    // ========================================================

    // CACHED MASTER PROMPT

    // ========================================================

    buffer.writeln(SystemPrompt.masterPrompt);

    // ========================================================

    // DYNAMIC CONTEXT

    // ========================================================

    buffer.writeln(
      _buildContextBlock(
        module: module,

        feature: feature,

        platform: platform,

        constraints: constraints,

        domain: domain,
      ),
    );

    // ========================================================

    // SCENARIO PLAN

    // ========================================================

    buffer.writeln(_buildSkeletonBlock(skeletons));

    // ========================================================

    // JSON CONTRACT

    // ========================================================

    buffer.writeln(_buildJsonContract());

    // ========================================================

    // FINAL EXECUTION RULE

    // ========================================================

    buffer.writeln('''

FINAL EXECUTION RULE:

Return ONLY valid JSON array.

No explanations.

No markdown.

''');

    return buffer.toString();
  }

  // ==========================================================

  // CONTEXT BLOCK

  // ==========================================================

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

  // ==========================================================

  // SKELETON BLOCK

  // ==========================================================

  static String _buildSkeletonBlock(List<Map<String, dynamic>> skeletons) {
    final buffer = StringBuffer();

    buffer.writeln('\n=== GENERATION PLAN ===');

    buffer.writeln('Generate EXACTLY ${skeletons.length} testcases.');

    buffer.writeln('STRICT CATEGORY LOCKING ENABLED.');

    for (int i = 0; i < skeletons.length; i++) {
      final sk = skeletons[i];

      buffer.writeln('''

CASE ${i + 1}

CATEGORY: ${sk['category']}

TYPE: ${sk['type']}

PRIORITY: ${sk['priority']}

INTENT: ${sk['intent_id']}

TITLE_DIRECTION: ${sk['title']}

''');
    }

    return buffer.toString();
  }

  // ==========================================================

  // JSON CONTRACT

  // ==========================================================

  static String _buildJsonContract() {
    final schema = [
      {
        "id": "TC_LOGIN_001",

        "title": "Valid login succeeds",

        "preconditions": ["User account exists", "Application is accessible"],

        "steps": [
          {
            "action": "Open login page",

            "data": "",

            "expected": "Login page loads successfully",
          },
        ],

        "expectedResult":
            "User is authenticated successfully and redirected to dashboard",

        "priority": "High",

        "type": "POSITIVE",
      },
    ];

    return '''

=== JSON CONTRACT ===

${jsonEncode(schema)}

''';
  }
}
