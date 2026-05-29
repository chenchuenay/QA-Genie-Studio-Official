import 'package:qa_genie/engine/parsers/schema_normalizer.dart';
import 'package:qa_genie/engine/parsers/ai_response_parser.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';
// lib/engine/orchestration/stages/parsing_stage.dart

class ParsingStage {
  final AiResponseParser _parser;
  final MalformedJsonSalvager _salvager;
  final PartialCaseExtractor _extractor;
  final SchemaNormalizer _normalizer;

  const ParsingStage({
    required AiResponseParser parser,
    required MalformedJsonSalvager salvager,
    required PartialCaseExtractor extractor,
    required SchemaNormalizer normalizer,
  }) : _parser = parser,
       _salvager = salvager,
       _extractor = extractor,
       _normalizer = normalizer;

  ParsingStageResult execute({required String rawResponse}) {
    if (rawResponse.trim().isEmpty) {
      return const ParsingStageResult(parsedCases: [], malformed: false);
    }

    try {
      final parsed = _parser.parse(rawResponse);
      final normalized = _normalizer.normalizeCases(parsed.cases);

      return ParsingStageResult(
        parsedCases: normalized,
        malformed: parsed.malformed,
      );
    } catch (_) {
      try {
        final salvaged = _salvager.salvage(rawResponse);
        final extracted = _extractor.extractValidCases([salvaged]);
        final normalized = _normalizer.normalizeCases(extracted);

        return ParsingStageResult(parsedCases: normalized, malformed: true);
      } catch (_) {
        return const ParsingStageResult(parsedCases: [], malformed: true);
      }
    }
  }
}

class ParsingStageResult {
  final List<Map<String, dynamic>> parsedCases;
  final bool malformed;

  const ParsingStageResult({
    required this.parsedCases,
    required this.malformed,
  });
}
