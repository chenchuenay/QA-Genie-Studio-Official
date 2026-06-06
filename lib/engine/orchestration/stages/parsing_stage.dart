import 'package:qa_genie/engine/parsers/ai_response_parser.dart';

class ParsingStage {
  final AiResponseParser _parser;

  const ParsingStage({required AiResponseParser parser}) : _parser = parser;

  ParsingStageResult execute({required String rawResponse}) {
    if (rawResponse.trim().isEmpty) {
      return const ParsingStageResult(
        parsedCases: [],
        malformed: false,
        parserErrors: ['Empty raw response'],
      );
    }

    final parsed = _parser.parse(rawResponse);
    return ParsingStageResult(
      parsedCases: parsed.cases,
      malformed: parsed.malformed,
      parserErrors: parsed.parserErrors,
    );
  }
}

class ParsingStageResult {
  final List<Map<String, dynamic>> parsedCases;
  final bool malformed;
  final List<String> parserErrors;
  const ParsingStageResult({
    required this.parsedCases,
    required this.malformed,
    this.parserErrors = const [],
  });
}
