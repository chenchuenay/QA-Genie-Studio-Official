import 'package:qa_genie/engine/pipeline/models/pipeline_models.dart';

class DiversityResult {
  final bool meetsTaxonomy;
  final Map<String, int> counts;

  DiversityResult({required this.meetsTaxonomy, required this.counts});
}

class DiversityEngine {
  static const taxonomy = [
    'validation',
    'security',
    'session',
    'resilience',
    'accessibility',
    'usability',
    'performance',
    'navigation',
    'persistence',
    'offline',
    'concurrency',
  ];

  DiversityResult evaluate(List<WorkingCase> cases) {
    final counts = <String, int>{};
    for (final tax in taxonomy) {
      counts[tax] = 0;
    }

    for (final tc in cases) {
      final intents = _detectIntents(tc);
      tc.metadata.diversitySignals.addAll(intents);
      
      for (final intent in intents) {
        if (counts.containsKey(intent)) {
          counts[intent] = counts[intent]! + 1;
        }
      }
      
      // Also account for the primary profile
      final profile = tc.metadata.semanticProfile;
      if (counts.containsKey(profile)) {
        counts[profile] = counts[profile]! + 1;
      }
    }

    final representedCount = counts.values.where((c) => c > 0).length;
    final meetsTaxonomy = representedCount >= 5; // Enterprise bar: at least 5 distinct intents
    
    return DiversityResult(meetsTaxonomy: meetsTaxonomy, counts: counts);
  }

  Set<String> _detectIntents(WorkingCase tc) {
    final text = '${tc.title} ${tc.expectedResult} ${tc.steps.map((s) => s.action).join(' ')}'.toLowerCase();
    final intents = <String>{};
    
    if (text.contains('login') || text.contains('auth')) intents.add('security');
    if (text.contains('invalid') || text.contains('error')) intents.add('validation');
    if (text.contains('navigate') || text.contains('screen')) intents.add('navigation');
    if (text.contains('save') || text.contains('persist')) intents.add('persistence');
    if (text.contains('offline') || text.contains('retry')) intents.add('resilience');
    if (text.contains('timeout') || text.contains('race')) intents.add('concurrency');
    
    return intents;
  }
}
