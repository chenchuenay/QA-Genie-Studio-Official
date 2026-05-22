import 'dart:math';
import 'dart:collection';
import 'package:qa_genie/core/debug/pipeline_debug_store.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';
import 'package:qa_genie/engine/context/domain_context_registry.dart';
import 'package:qa_genie/core/quality/behavioral_workflow_integrity_evaluator.dart';
import 'package:qa_genie/data/models/test_case_model.dart';

class QaRealismEnforcer {
  static final _random = Random();
  static final Set<String> _usedTitles = {};
  static final Set<String> _usedPhrases = {};
  static final Queue<String> _recentPhrases = Queue();
  static const int _cooldownSize = 5;

  static int validateSuite(List<TestCaseModel> cases, String platform) {
    return BehavioralWorkflowIntegrityEvaluator.evaluate(cases, platform);
  }

  static String enforceLength(String value, int max) {
    if (value.length <= max) return value;
    final safe = value.substring(0, max);
    final lastSpace = safe.lastIndexOf(' ');
    return lastSpace > 0 ? safe.substring(0, lastSpace) : safe;
  }

  static String _normalize(String input) {
    return input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static void _trackPhrase(String phrase) {
    final normalized = _normalize(phrase);
    if (!_usedPhrases.contains(normalized)) {
      _usedPhrases.add(normalized);
      PipelineDebugStore.realismPhraseVariationsUsed = _usedPhrases.length;
    }
  }

  static String _getNonRepeating(List<String> pool) {
    final available = pool.where((p) => !_recentPhrases.contains(p)).toList();
    final choice = available.isNotEmpty ? available[_random.nextInt(available.length)] : pool[_random.nextInt(pool.length)];
    if (_recentPhrases.length >= _cooldownSize) _recentPhrases.removeFirst();
    _recentPhrases.add(choice);
    return choice;
  }

  static String humanizeTitle(String title, String context) {
    if (_usedTitles.length > 5000) _usedTitles.clear();
    
    final terms = DomainContextRegistry.getTerms(context);
    final term = terms[_random.nextInt(terms.length)];
    final variations = [
      'User completes {action} and {term} state persists after interruption',
      'Verify {action} resumes from the previous {term} state',
      'Confirm {action} prevents duplicate {term} creation',
      'Validated {action} maintains active {term} after recovery',
      'Previously entered {term} remains visible after {action}',
    ];
    
    final action = title.toLowerCase().replaceAll('verify', '').trim();
    final template = variations[_random.nextInt(variations.length)];
    final humanized = template
        .replaceAll('{action}', action)
        .replaceAll('{term}', term);
        
    final normalized = _normalize(humanized);
    if (_usedTitles.contains(normalized)) {
      PipelineDebugStore.duplicateTitlesPrevented++;
      return enforceLength(humanized + ' [v${_random.nextInt(100)}]', 200);
    }
    
    if (humanized != title) {
        PipelineDebugStore.humanizedTitlesCount++;
    }
    
    _usedTitles.add(normalized);
    _trackPhrase(humanized);
    return enforceLength(humanized, 200);
  }

  static String humanizeExpectedResult(String base, String context, {ExecutionIntent? intent, String platform = 'Web'}) {
    return base;
  }
  
  static String humanizeStepExpectation(String base, String context) {
    List<String> pool;
    if (context.contains('session')) {
      pool = [
        'User remains authenticated after browser refresh.',
        'Session persists across multiple active tabs.',
        'Login state remains cached after reopening tab.'
      ];
    } else if (context.contains('retry')) {
      pool = [
        'Retry resumes from the interrupted workflow step.',
        'Action continues without duplicate record creation.',
        'Form state is restored from previous draft.'
      ];
    } else if (context.contains('validation')) {
      pool = [
        'Validation feedback appears near affected fields.',
        'User remains on current form for correction.',
        'Previously entered values are preserved after failure.'
      ];
    } else {
      pool = [
        'Updated values remain visible after processing.',
        'Workflow continues without resetting form state.',
        'Interface confirms the change with no data loss.'
      ];
    }
    
    final selected = _getNonRepeating(pool);
    _trackPhrase(selected);
    return enforceLength('$base $selected', 140);
  }

  static bool isGarbage(String text) {
    final lower = text.toLowerCase();
    final banned = [
      'system processes input correctly',
      'operation completes successfully',
      'workflow integrity maintained',
      'successful update reflected',
      'ui confirms successful change'
    ];
    return banned.any((p) => lower.contains(p));
  }
}
