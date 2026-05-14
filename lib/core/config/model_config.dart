enum ModelType { production, testing }

class ModelConfig {
  final String baseUrl;
  final String modelName;
  final int maxTokens;
  final double temperature;

  ModelConfig({
    required this.baseUrl,
    required this.modelName,
    this.maxTokens = 8000,
    this.temperature = 1.0,
  });

  static ModelConfig get(ModelType type) {
    switch (type) {
      case ModelType.production:
        return ModelConfig(
          baseUrl:
              'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent',
          modelName: 'gemini-1.5-flash',
          maxTokens: 8000,
          temperature: 1.0,
        );
      case ModelType.testing:
        return ModelConfig(
          baseUrl:
              'https://generativelanguage.googleapis.com/v1/models/gemini-1.5:generateContent',
          modelName: 'gemini-1.5',
          maxTokens: 8000,
          temperature: 0.7,
        );
    }
  }
}
