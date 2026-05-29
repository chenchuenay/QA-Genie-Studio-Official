import 'dart:convert';
import 'package:qa_genie/engine/parsers/schema_normalizer.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';

class ParsedAiResponse {
  final List<Map<String, dynamic>> cases;
  final bool salvaged;
  final bool malformed;

  const ParsedAiResponse({
    required this.cases,
    required this.salvaged,
    required this.malformed,
  });
}

class AiResponseParser {
  final MalformedJsonSalvager _salvager;
  final SchemaNormalizer _normalizer;
  final PartialCaseExtractor _extractor;

  const AiResponseParser({
    MalformedJsonSalvager salvager = const MalformedJsonSalvager(),
    SchemaNormalizer normalizer = const SchemaNormalizer(),
    PartialCaseExtractor extractor = const PartialCaseExtractor(),
  }) : _salvager = salvager,
       _normalizer = normalizer,
       _extractor = extractor;

  ParsedAiResponse parse(String rawResponse) {
    if (rawResponse.trim().isEmpty) {
      return const ParsedAiResponse(
        cases: [],
        salvaged: false,
        malformed: false,
      );
    }

    try {
      return _parseInternal(rawResponse, salvaged: false);
    } catch (_) {
      final repaired = _salvager.salvage(rawResponse);
      try {
        return _parseInternal(repaired, salvaged: true);
      } catch (_) {
        return const ParsedAiResponse(
          cases: [],
          salvaged: true,
          malformed: true,
        );
      }
    }
  }

  ParsedAiResponse _parseInternal(String response, {required bool salvaged}) {
    final decoded = jsonDecode(response);
    List<dynamic> rawCases = [];
    if (decoded is List) {
      rawCases = decoded;
    } else if (decoded is Map<String, dynamic>) {
      rawCases = decoded['testCases'] ?? [];
    }
    final validCases = _extractor.extractValidCases(rawCases);
    final normalized = _normalizer.normalizeCases(validCases);
    return ParsedAiResponse(
      cases: normalized,
      salvaged: salvaged,
      malformed: false,
    );
  }
}
