class PipelineDebugStore {
  static String lastProvider = '';
  static String lastRawResponse = '';
  static String lastCleanedResponse = '';
  static String lastFinalPrompt = '';
  static int cleanerRepairCount = 0;

  /// JSON structures successfully merged into the decode candidate list.
  static int recoveredObjectCount = 0;

  /// Salvage-phase chunk decode failures (does not include per-field item skips).
  static int rejectedObjectCount = 0;

  /// Full-string `jsonDecode` failed so salvage heuristics were engaged.
  static bool partialRecoveryUsed = false;

  /// Entries skipped while mapping JSON maps into models (thin title, dedup-at-parse, invalid).
  static int malformedObjectsSkipped = 0;

  static void resetParserSalvageCounters() {
    recoveredObjectCount = 0;
    rejectedObjectCount = 0;
    partialRecoveryUsed = false;
    malformedObjectsSkipped = 0;
  }

  static void reset() {
    lastProvider = '';
    lastRawResponse = '';
    lastCleanedResponse = '';
    lastFinalPrompt = '';
    cleanerRepairCount = 0;
    resetParserSalvageCounters();
  }
}
