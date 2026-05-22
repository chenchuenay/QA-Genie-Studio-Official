abstract class AiProvider {
  Future<String> generate(String prompt, {int? maxTokens});
}
