import 'dart:convert';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/data/datasources/remote/remote_api_source.dart';
// ============================================================
// FILE: lib/data/repositories/generation_repository.dart
// ============================================================

/// ===============================================================
///
/// GENERATION REPOSITORY
///
/// RESPONSIBILITIES:
/// - communicates with remote AI source
/// - converts raw response -> models
/// - isolates parsing layer
///
/// MUST NOT:
/// - perform orchestration
/// - perform validation
/// - perform repair
/// - access UI
///
/// ===============================================================
class GenerationRepository {
  final RemoteApiSource _remote;

  const GenerationRepository({required RemoteApiSource remote})
    : _remote = remote;

  // ============================================================
  // GENERATE RAW CASES
  // ============================================================

  Future<List<TestCaseModel>> generateCases({
    required GenerationDto dto,
  }) async {
    final raw = await _remote.generateTestCases(dto: dto);

    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      throw Exception('AI response is not a List');
    }

    return decoded
        .whereType<Map>()
        .map((e) => TestCaseModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
