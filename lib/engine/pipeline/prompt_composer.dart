import 'package:qa_genie/engine/pipeline/generation_context.dart';

class PromptComposer {
  String compose(GenerationContext context) {
    final sb = StringBuffer();
    sb.writeln(
      'You are a senior QA engineer simulating real-world user behavior and exhaustive testing scenarios. Generate enterprise-grade, execution-ready manual test cases.',
    );
    sb.writeln('Module: ${context.module}');
    sb.writeln('Feature: ${context.feature}');
    sb.writeln('Platform: ${context.platform}');
    sb.writeln('Domain: ${context.inferredDomain}');
    sb.writeln(
      'Return ONLY a raw JSON array. Exclude markdown, comments, headings, or explanatory text.',
    );
    sb.writeln(
      'Required output schema: id,title,module,feature,platform,preconditions,steps,expectedResult,priority,status,type,actualResult.',
    );
    sb.writeln('Each step must be an object with action, data, and expected.');
    sb.writeln(
      'Simulate human-like QA reasoning: include common user errors, boundary conditions, edge cases, and negative scenarios. Think about interrupted flows and state/session transitions. Ensure realistic validation chains.',
    );
    sb.writeln(
      'Ensure expected results are specific, measurable, verifiable, and describe observable outcomes. Avoid vague phrases like "system works correctly" or generic messages like "validation message displayed".',
    );
    sb.writeln(
      'Generate concise, actionable steps and clear, verifiable outcomes. Use platform-specific terminology.',
    );
    sb.writeln(
      'Avoid AI-style repetition, filler, generic phrases, or superficial diversity. Focus on intentional, execution-worthy cases that mimic a skilled manual tester.',
    );
    sb.writeln(
      'Ensure balanced coverage: prioritize realistic positive, negative, security, and session-related scenarios. Avoid unrealistic security exploits or overly broad negative cases.',
    );
    sb.writeln(
      'Use concise, actionable language suitable for export to tools like Jira and Xray.',
    );
    sb.writeln(
      'Use only reserved documentation domains when generating emails and URLs.',
    );
    sb.writeln('Return test cases as a valid JSON array only.');

    for (final skeleton in context.skeletons) {
      sb.writeln('- ${skeleton['title']} [${skeleton['category']}]');
    }

    context.promptMetadata['rawPrompt'] = sb.toString();
    context.promptMetadata['promptVersion'] = 'v1.6'; // Updated version for enhanced prompt
    context.promptMetadata['generatedAt'] = DateTime.now()
        .toUtc()
        .toIso8601String();
    return sb.toString();
  }
}
