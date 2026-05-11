import 'package:qa_app/core/database/database_service.dart';
import 'package:qa_app/engine/generation_result.dart';
import 'package:qa_app/engine/generation_service.dart';
import 'package:qa_app/features/monetization/logic/usage_manager.dart';

class GenerateTestCasesUseCase {
  final GenerationService _service = GenerationService();

  Future<GenerationResult> execute({
    required String module,
    required String feature,
    required String platform,
    String? notes,
  }) async {
    final maxCases = await UsageManager.maxCasesPerBatch();

    final db = await DatabaseService.db;
    int startIndex = 1;
    await db.transaction((txn) async {
      final prefix =
          'TC_${module.replaceAll(' ', '_').toUpperCase()}_${feature.replaceAll(' ', '_').toUpperCase()}_';
      final rows = await txn.rawQuery(
        'SELECT MAX(CAST(SUBSTR(id, LENGTH(?)+1) AS INTEGER)) as max_idx FROM test_cases WHERE id LIKE ?',
        [prefix, '$prefix%'],
      );
      final maxIdx = rows.first['max_idx'];
      startIndex = (maxIdx != null ? (maxIdx as int) : 0) + 1;
    });

    final result = await _service.execute(
      module: module,
      feature: feature,
      platform: platform,
      maxCases: maxCases,
      notes: notes,
      startIndex: startIndex,
    );

    return result;
  }
}
