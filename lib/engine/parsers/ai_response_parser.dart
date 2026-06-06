import 'dart:convert';
import 'package:qa_genie/engine/parsers/schema_normalizer.dart';
import 'package:qa_genie/engine/parsers/partial_case_extractor.dart';
import 'package:qa_genie/engine/parsers/malformed_json_salvager.dart';

class ParsedAiResponse {
  final List<Map<String, dynamic>> cases;
  final bool salvaged;
  final bool malformed;
  final List<String> parserErrors;
  const ParsedAiResponse({
    required this.cases,
    required this.salvaged,
    required this.malformed,
    this.parserErrors = const [],
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
    final errors = <String>[];
    if (rawResponse.trim().isEmpty) {
      errors.add('Raw AI response is empty.');
      return ParsedAiResponse(
        cases: [],
        salvaged: false,
        malformed: false,
        parserErrors: errors,
      );
    }

    try {
      return _parseInternal(rawResponse, salvaged: false, errors: errors);
    } catch (e) {
      errors.add('Initial parse failed: $e');
      final repaired = _salvager.salvage(rawResponse);
      try {
        return _parseInternal(repaired, salvaged: true, errors: errors);
      } catch (e2) {
        errors.add('Salvaged parse also failed: $e2');
        return ParsedAiResponse(
          cases: [],
          salvaged: true,
          malformed: true,
          parserErrors: errors,
        );
      }
    }
  }

  ParsedAiResponse _parseInternal(
    String response, {
    required bool salvaged,
    required List<String> errors,
  }) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response);
    } catch (e) {
      errors.add('JSON decode error: $e');
      rethrow;
    }

    List<dynamic> rawCases = [];
    if (decoded is List) {
      rawCases = decoded;
    } else if (decoded is Map<String, dynamic>) {
      rawCases = decoded['testCases'] ?? [];
      if (rawCases.isEmpty && decoded.containsKey('testCases') == false) {
        errors.add('No "testCases" array found in response map.');
      }
    } else {
      errors.add(
        'Response is neither array nor object (type: ${decoded.runtimeType})',
      );
    }

    final validCases = _extractor.extractValidCases(rawCases, errors);
    final normalized = _normalizer.normalizeCases(validCases);
    return ParsedAiResponse(
      cases: normalized,
      salvaged: salvaged,
      malformed: rawCases.isEmpty && validCases.isEmpty,
      parserErrors: errors,
    );
  }
}
