/// Defines where the testcase originated from.
/// Used for forensic tracing and pipeline analytics.
enum CaseSource {
  ai,
  fallback,
  repaired,
  repairedAi,
  emergency,
  imported,
  manual,
}

extension CaseSourceExtension on CaseSource {
  String get value {
    switch (this) {
      case CaseSource.ai:
        return 'AI';

      case CaseSource.fallback:
        return 'Fallback';

      case CaseSource.repaired:
      case CaseSource.repairedAi:
        return 'Repaired';

      case CaseSource.emergency:
        return 'Emergency';

      case CaseSource.imported:
        return 'Imported';

      case CaseSource.manual:
        return 'Manual';
    }
  }

  bool get isAiGenerated {
    return this == CaseSource.ai ||
        this == CaseSource.fallback ||
        this == CaseSource.repaired ||
        this == CaseSource.repairedAi ||
        this == CaseSource.emergency;
  }

  bool get isRecoverySource {
    return this == CaseSource.fallback ||
        this == CaseSource.repaired ||
        this == CaseSource.repairedAi ||
        this == CaseSource.emergency;
  }
}
