import 'package:qa_genie/engine/pipeline/system_prompt.dart';
import 'package:qa_genie/engine/pipeline/generation_context.dart';

class PromptComposer {
  String compose(GenerationContext context) {
    final sb = StringBuffer();

    // SINGLE SOURCE OF TRUTH
    sb.writeln(SystemPrompt.systemInstruction);

    sb.writeln('PROMPT_VERSION=${SystemPrompt.version}');
    sb.writeln('');

    sb.writeln('REQUEST_DETAILS:');
    sb.writeln('MODULE=${context.module}');
    sb.writeln('FEATURE=${context.feature}');
    sb.writeln('PLATFORM=${context.platform}');
    sb.writeln('DOMAIN=${context.inferredDomain}');
    sb.writeln('');

    if (context.notes.trim().isNotEmpty) {
      sb.writeln('USER_CONSTRAINTS=${context.notes.trim()}');
      sb.writeln('');
    }

    sb.writeln(SystemPrompt.platformRules(context.platform));

    sb.writeln('');
    sb.writeln('GENERATE EXACTLY ${context.skeletons.length} TEST CASES.');

    sb.writeln('MATCH EACH SCENARIO CONTRACT EXACTLY WITHOUT CHANGING INTENT.');

    sb.writeln('');
    sb.writeln('SCENARIO_CONTRACTS:');

    for (final skeleton in context.skeletons) {
      sb.writeln(
        '- ${skeleton['title']} | '
        'category=${skeleton['category']} | '
        'type=${skeleton['type']}',
      );
    }

    context.promptMetadata['rawPrompt'] = sb.toString();
    context.promptMetadata['promptVersion'] = SystemPrompt.version;
    context.promptMetadata['generatedAt'] = DateTime.now()
        .toUtc()
        .toIso8601String();

    return sb.toString().trim();
  }
}
