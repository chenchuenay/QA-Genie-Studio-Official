import 'package:qa_genie/core/network/providers/ai_provider.dart';
import 'package:qa_genie/core/network/providers/groq_provider.dart';
import 'package:qa_genie/core/network/providers/gemini_provider.dart';

class ProviderFactory {
  static String activeProvider = 'unknown';

  static String activeModel = 'unknown';

  static const String provider = String.fromEnvironment(
    'AI_PROVIDER',
    defaultValue: 'gemini',
  );

  static AiProvider create() {
    switch (provider.toLowerCase()) {
      case 'groq':
        activeProvider = 'groq';
        activeModel = 'llama-3.3-70b-versatile';
        return GroqProvider();

      case 'gemini':
      default:
        activeProvider = 'gemini';
        activeModel = 'gemini-2.5-pro';
        return GeminiProvider();
    }
  }
}
