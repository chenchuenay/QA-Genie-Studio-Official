// Placeholder for GenerationApiResponse model
class GenerationApiResponse {
  final String text;
  final String modelUsed;
  final int totalTokenCount;

  GenerationApiResponse({
    this.text = '',
    this.modelUsed = 'unknown',
    this.totalTokenCount = 0,
  });
}
