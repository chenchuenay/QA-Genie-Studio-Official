import 'dart:convert';
import 'package:qa_genie/engine/prompts/system_prompt.dart';

class PromptComposer {
  const PromptComposer();

  static String compose({
    required String module,
    required String feature,
    required String platform,
    required List<Map<String, dynamic>> skeletons,
    String? constraints,
    String domain = 'general',
  }) {
    final buffer = StringBuffer();

    // Static cached master prompt
    buffer.writeln(SystemPrompt.masterPrompt);

    // Dynamic context
    buffer.writeln(
      _buildContextBlock(
        module: module,
        feature: feature,
        platform: platform,
        constraints: constraints,
        domain: domain,
      ),
    );

    // Dynamic skeleton plan
    buffer.writeln(_buildSkeletonBlock(skeletons));

    // JSON contract example (helps model understand schema)
    buffer.writeln(_buildJsonContract());

    // Final instruction
    buffer.writeln('''
FINAL EXECUTION RULE:

Return ONLY valid JSON array.

No explanations.

No markdown.
''');

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

  static String _buildJsonContract() {
    const schema = [
      {
        "id": "TC_LOGIN_001",
        "title": "Valid login succeeds",
        "module": "Login",
        "feature": "Member login",
        "platform": "WEB",
        "preconditions": ["Member account exists", "Application is accessible"],
        "testData": "email=member@example.com&password=ValidPass123!",
        "steps": [
          {
            "action": "Open login page",
            "data": "",
            "expected": "Login page loads successfully",
          },
        ],
        "expectedResult":
            "Member is authenticated successfully and redirected to dashboard",
        "priority": "High",
        "type": "POSITIVE",
        "categoryLock": "positive",
        "intent_id": "valid_login",
      },
    ];
    return '''
=== JSON CONTRACT ===
${jsonEncode(schema)}
''';
  }
}
