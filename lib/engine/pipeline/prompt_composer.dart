import 'package:qa_genie/core/prompts/system_prompt.dart';

class PromptComposer {
  String compose({
    required String module,
    required String feature,
    required String platform,
    required String inferredDomain,
    required String notes,
    required List<Map<String, dynamic>> skeletons,
    required Map<String, dynamic> promptMetadata,
  }) {
    final sb = StringBuffer();

    // SINGLE SOURCE OF TRUTH
    sb.writeln(SystemPrompt.systemInstruction);

    sb.writeln('PROMPT_VERSION=${SystemPrompt.version}');
    sb.writeln('');

    sb.writeln('REQUEST_DETAILS:');
    sb.writeln('MODULE=$module');
    sb.writeln('FEATURE=$feature');
    sb.writeln('PLATFORM=$platform');
    sb.writeln('DOMAIN=$inferredDomain');
    sb.writeln('');

    if (notes.trim().isNotEmpty) {
      sb.writeln('USER_CONSTRAINTS=${notes.trim()}');
      sb.writeln('');
    }

    sb.writeln(SystemPrompt.platformRules(platform));

    sb.writeln('');
    sb.writeln('GENERATE EXACTLY ${skeletons.length} TEST CASES.');

    sb.writeln('MATCH EACH SCENARIO CONTRACT EXACTLY WITHOUT CHANGING INTENT.');

    sb.writeln('');
    sb.writeln('SCENARIO_CONTRACTS:');

    for (final skeleton in skeletons) {
      sb.writeln(
        '- ${skeleton['title']} | '
        'category=${skeleton['category']} | '
        'type=${skeleton['type']}',
      );
    }

    promptMetadata['rawPrompt'] = sb.toString();
    promptMetadata['promptVersion'] = SystemPrompt.version;
    promptMetadata['generatedAt'] = DateTime.now()
        .toUtc()
        .toIso8601String();

    return sb.toString().trim();
  }
}
