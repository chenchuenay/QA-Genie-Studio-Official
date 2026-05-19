class PipelineDebugStore {
  static String lastProvider = '';

  static String lastRawResponse = '';

  static String lastCleanedResponse = '';

  static String lastFinalPrompt = '';

  static int lastParsedCount = 0;

  static int lastApiDurationMs = 0;

  static bool partialRecoveryUsed = false;

  static int recoveredObjectCount = 0;

  static int rejectedObjectCount = 0;

  static int malformedObjectsSkipped = 0;

  static int cleanerRepairCount = 0;

  static void resetParserSalvageCounters() {
    partialRecoveryUsed = false;
    recoveredObjectCount = 0;
    rejectedObjectCount = 0;
    malformedObjectsSkipped = 0;
    cleanerRepairCount = 0;
  }

  static void resetAll() {
    lastProvider = '';
    lastRawResponse = '';
    lastCleanedResponse = '';
    lastFinalPrompt = '';
    lastParsedCount = 0;
    lastApiDurationMs = 0;

    resetParserSalvageCounters();
  }
}
