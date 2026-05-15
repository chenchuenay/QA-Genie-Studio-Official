import 'ai_provider.dart';
import 'gemini_provider.dart';
import 'groq_provider.dart';

class ProviderFactory {
  static AiProvider create() {
    const provider = String.fromEnvironment('AI_PROVIDER', defaultValue: 'gemini');
    switch (provider) {
      case 'groq':
        return GroqProvider();
      case 'gemini':
      default:
        return GeminiProvider();
    }
  }
}
