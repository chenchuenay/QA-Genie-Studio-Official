class PipelineDebugStore {
  static String lastProvider = '';

  static String lastRawResponse = '';
  static String lastRawProviderResponse = '';
  static String lastRawProviderPayload = '';

  static String lastFullRawAiResponse = '';
  static String lastFullCleanedResponse = '';
  static String lastFullValidatedDump = '';
  static String lastFullFinalDump = '';
  static String lastTimestamp = '';

  static String lastCleanedResponse = '';
  static String lastFinishReason = '';

  static String lastFinalPrompt = '';

  static int lastParsedCount = 0;

  static int lastApiDurationMs = 0;

  static bool partialRecoveryUsed = false;
  static bool truncatedResponseDetected = false;

  static int recoveredObjectCount = 0;
  static int rejectedObjectCount = 0;
  static int malformedObjectsSkipped = 0;
  static int cleanerRepairCount = 0;
  static int invalidCasesDropped = 0;
  static int rawOpenBrackets = 0;
  static int rawCloseBrackets = 0;
  static String rawTailSnapshot = '';
  static int recoveredCount = 0;
  static int truncatedTailLength = 0;
  static int corruptionIndex = -1;
  static int safeObjectCount = 0;
  static int humanizedTitlesCount = 0;
  static int duplicateTitlesPrevented = 0;
  static int realismPhraseVariationsUsed = 0;

  static List<Map<String, dynamic>> rejectedObjects = [];
  static List<Map<String, dynamic>> repairedObjects = [];
  static List<Map<String, dynamic>> realismInjections = [];
  static List<Map<String, dynamic>> finalObjects = [];

  static int recoveredObjects = 0;
  static int droppedObjects = 0;
  static int finalAiCases = 0;
  static int finalFallbackCases = 0;
  static bool repairActivated = false;

  static int estimatedInputTokens = 0;
  static int estimatedOutputTokens = 0;
  static int estimatedSavedTokens = 0;
  
  static bool schemaConstrained = false;
  static bool providerFallbackTriggered = false;
  static bool providerRequestSucceeded = false;
  static int providerHttpStatus = -1;
  static bool providerReturnedContent = false;
  static bool fallbackActivated = false;

  static void resetParserSalvageCounters() {
    partialRecoveryUsed = false;
    recoveredObjectCount = 0;
    rejectedObjectCount = 0;
    malformedObjectsSkipped = 0;
    cleanerRepairCount = 0;
    invalidCasesDropped = 0;
    rejectedObjects = [];
    repairedObjects = [];
    realismInjections = [];
    finalObjects = [];
  }

  static void resetAll() {
    lastProvider = '';
    lastRawResponse = '';
    lastRawProviderResponse = '';
    lastRawProviderPayload = '';
    lastFullRawAiResponse = '';
    lastFullCleanedResponse = '';
    lastFullValidatedDump = '';
    lastFullFinalDump = '';
    lastTimestamp = '';
    lastCleanedResponse = '';
    lastFinishReason = '';
    lastFinalPrompt = '';
    lastParsedCount = 0;
    lastApiDurationMs = 0;
    estimatedInputTokens = 0;
    estimatedOutputTokens = 0;
    estimatedSavedTokens = 0;

    resetParserSalvageCounters();
    recoveredObjects = 0;
    droppedObjects = 0;
    rawOpenBrackets = 0;
    rawCloseBrackets = 0;
    rawTailSnapshot = '';
    
    schemaConstrained = false;
    providerFallbackTriggered = false;
    providerRequestSucceeded = false;
    providerHttpStatus = -1;
    providerReturnedContent = false;
    fallbackActivated = false;
  }
}
