import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/engine/models/pipeline_models.dart';
import 'package:qa_genie/domain/entities/finalized_test_case.dart';

class FinalizationStage {
  List<FinalizedTestCase> execute({
    required List<WorkingCase> cases,
    required String module,
  }) {
    final normalizedModule = _normalizeModule(module);
    final finalized = <FinalizedTestCase>[];

    for (int i = 0; i < cases.length; i++) {
      final working = cases[i];
      final canonicalSteps = working.steps.map((step) {
        return TestStep(
          action: step.action,
          data: step.data,
          expected: step.expected,
        );
      }).toList();

      finalized.add(
        FinalizedTestCase(
          id: 'TC_${normalizedModule}_${(i + 1).toString().padLeft(3, '0')}',
          title: _normalizeTitle(working.title),
          preconditions: working.preconditions,
          testData: working.testData,
          steps: canonicalSteps,
          expectedResult: working.expectedResult,
          actualResult: '',
          priority: working.priority,
          status: 'Not Executed',
          type: working.type,
          module: working.module,
          feature: working.feature,
          platform: working.platform,
          source: working.metadata.source,
          dbId: null,
        ),
      );
    }
    return finalized;
  }

  String _normalizeModule(String module) {
    return module
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .toUpperCase();
  }

  String _normalizeTitle(String title) {
    return _splitDualConcept(title.trim().replaceAll(RegExp(r'\s+'), ' '));
  }

  static bool _isSecondConcept(String phrase) {
    final low = phrase.toLowerCase().trim();
    final words = low.split(RegExp(r'\s+'));
    if (words.isEmpty) return false;

    const newConceptStarts = {
      'verify', 'check', 'ensure', 'confirm', 'test', 'validate',
      'login', 'logout', 'register', 'signup', 'signin',
      'delete', 'remove', 'cancel', 'undo', 'create', 'add',
      'update', 'edit', 'modify', 'view', 'show', 'navigate',
      'submit', 'send', 'post', 'upload', 'download', 'export', 'import',
      'receive', 'search', 'approve', 'reject', 'accept',
      'pay', 'checkout', 'purchase', 'book', 'reschedule', 'schedule',
      'should', 'must', 'will', 'user', 'system', 'app',
    };

    if (newConceptStarts.contains(words.first)) return true;

    if (words.first == 'the' && words.length > 1) {
      return newConceptStarts.contains(words[1]);
    }

    return false;
  }

  String _splitDualConcept(String title) {
    int searchStart = 0;
    while (true) {
      final andIndex = title.indexOf(' and ', searchStart);
      if (andIndex < 0) break;

      final afterAnd = title.substring(andIndex + 5).trimLeft();
      if (afterAnd.isNotEmpty && _isSecondConcept(afterAnd)) {
        return title.substring(0, andIndex).trim();
      }
      searchStart = andIndex + 5;
    }
    return title;
  }
}