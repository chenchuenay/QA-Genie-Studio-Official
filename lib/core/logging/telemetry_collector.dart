import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'error_registry.dart';
import 'logging_config.dart';
import 'telemetry_models.dart';
import 'telemetry_snapshot.dart';
import 'package:crypto/crypto.dart';

class TelemetryCollector {
  static final TelemetryCollector _instance = TelemetryCollector._internal();
  factory TelemetryCollector() => _instance;
  TelemetryCollector._internal();

  String sessionId = '';
  DateTime timestamp = DateTime.now();
  String provider = '';
  String model = '';
  String mode = '';
  String generationState = 'init';

  // System & Build metadata
  bool forensicMode = LoggingConfig.forensicLogging;
  String buildMode = kDebugMode ? 'debug' : (kProfileMode ? 'profile' : 'release');
  String appVersion = '1.2.100'; 
  String buildNumber = '101';
  String os = Platform.operatingSystem;
  String osVersion = Platform.operatingSystemVersion;
  String device = 'Unknown';
  String locale = ui.PlatformDispatcher.instance.locale.toString();
  String timezone = DateTime.now().timeZoneName;
  String flutterVersion = 'unknown_runtime'; 
  String dartVersion = Platform.version;

  String module = '';
  String feature = '';
  String platform = '';
  String constraints = '';
  String prompt = '';
  String rawResponse = '';
  int requestedCount = 0;
  int promptTokensEstimate = 0;
  int responseTokensEstimate = 0;
  bool sessionCompleted = false;

  // Pipeline Metrics
  int repairedCases = 0;
  int fallbackGeneratedCases = 0;
  String fallbackReason = '';
  DedupTrace? dedupTrace;

  bool fallbackTriggered = false;
  String rawErrorBody = '';

  String integrityHash = '';
  int totalDurationMs = 0;
  final List<String> stateTransitions = [];
  final List<dynamic> finalCasesJson = [];
  final List<ValidatorTrace> validatorTraces = [];
  final List<RepairTrace> repairTraces = [];
  final List<ExportTrace> exportTraces = [];
  final List<UiErrorTrace> uiErrorTraces = [];

  ParserTrace? parserTrace;
  PerformanceTrace? performanceTrace;
  NetworkTrace? networkTrace;
  FallbackTrace? fallbackTrace;

  final ErrorRegistry errorRegistry = ErrorRegistry();

  Future<void> initializeSystemSnapshot() async {
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
      buildNumber = info.buildNumber;
      
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        device = '${android.brand} ${android.model}';
        osVersion = android.version.release;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        device = ios.name;
        osVersion = ios.systemVersion;
      }
    } catch (e) {
      debugPrint('Failed to initialize system snapshot: $e');
    }
  }

  void clear() {
    validatorTraces.clear();
    repairTraces.clear();
    exportTraces.clear();
    uiErrorTraces.clear();
    finalCasesJson.clear();
    stateTransitions.clear();
    parserTrace = null;
    performanceTrace = null;
    networkTrace = null;
    fallbackTrace = null;
    
    repairedCases = 0;
    fallbackGeneratedCases = 0;
    fallbackReason = '';
    dedupTrace = null;
    
    sessionCompleted = false;
    generationState = 'init';
    fallbackTriggered = false;
    rawErrorBody = '';
  }

  void startSession(String m, String p, String mdl) {
    clear();
    mode = m;
    provider = p;
    model = mdl;
    timestamp = DateTime.now();
    sessionId = timestamp.millisecondsSinceEpoch.toString();
    stateTransitions.add('init');
  }

  void updateGenerationState(String state) {
    generationState = state;
    if (stateTransitions.isEmpty || stateTransitions.last != state) {
      stateTransitions.add(state);
    }
  }

  void recordPrompt(String p, {required int promptCharacters, required int promptTokenEstimate}) {
    prompt = p;
    promptTokensEstimate = promptTokenEstimate;
  }

  void recordRawResponse(String response) {
    rawResponse = response;
    responseTokensEstimate = response.length ~/ 4;
  }

  void recordNetworkTrace(NetworkTrace trace) => networkTrace = trace;
  void recordParserTrace(ParserTrace trace) => parserTrace = trace;
  void recordValidatorTrace(ValidatorTrace trace) => validatorTraces.add(trace);
  void recordRepairTrace(RepairTrace trace) => repairTraces.add(trace);
  void recordExportTrace(ExportTrace trace) => exportTraces.add(trace);
  void recordUiErrorTrace(UiErrorTrace trace) => uiErrorTraces.add(trace);
  void recordFallbackTrace(FallbackTrace trace) => fallbackTrace = trace;
  
  void recordFallback({required bool triggered, required String reason, int generatedCases = 0}) {
    fallbackTriggered = triggered;
    fallbackReason = reason;
    fallbackGeneratedCases = generatedCases;
  }

  void recordRawErrorBody(String body) {
    rawErrorBody = body;
  }

  void recordFinalCases(List<dynamic> cases) {
    finalCasesJson..clear()..addAll(cases);
  }

  void recordPerformanceTrace(PerformanceTrace trace) {
    performanceTrace = trace;
    totalDurationMs = trace.totalMs;
    sessionCompleted = true;
  }

  void recordDedupStats({
    required int aiInputCount,
    required int duplicatesRemoved,
    required int finalOutputCount,
  }) {
    dedupTrace = DedupTrace(
      aiInputCount: aiInputCount,
      duplicatesRemoved: duplicatesRemoved,
      fallbackGeneratedCount: 0,
      finalOutputCount: finalOutputCount,
    );
  }

  String _generateIntegrityHash() {
    final raw = jsonEncode({
      "prompt": prompt,
      "rawResponse": rawResponse,
      "finalCases": finalCasesJson,
    });
    return sha256.convert(utf8.encode(raw)).toString();
  }

  TelemetrySnapshot freeze() {
    integrityHash = _generateIntegrityHash();
    return TelemetrySnapshot(
      sessionId: sessionId,
      timestamp: timestamp,
      provider: provider,
      model: model,
      mode: mode,
      generationState: generationState,
      forensicMode: forensicMode,
      buildMode: buildMode,
      appVersion: appVersion,
      buildNumber: buildNumber,
      os: os,
      osVersion: osVersion,
      device: device,
      locale: locale,
      timezone: timezone,
      flutterVersion: flutterVersion,
      dartVersion: dartVersion,
      module: module,
      feature: feature,
      platform: platform,
      constraints: constraints,
      requestedCount: requestedCount,
      prompt: prompt,
      rawResponse: rawResponse,
      promptTokensEstimate: promptTokensEstimate,
      responseTokensEstimate: responseTokensEstimate,
      sessionCompleted: sessionCompleted,
      repairedCases: repairedCases,
      fallbackGeneratedCases: fallbackGeneratedCases,
      fallbackReason: fallbackReason,
      dedupTrace: dedupTrace,
      integrityHash: integrityHash,
      totalDurationMs: totalDurationMs,
      stateTransitions: stateTransitions,
      finalCasesJson: finalCasesJson,
      validatorTraces: validatorTraces,
      repairTraces: repairTraces,
      exportTraces: exportTraces,
      uiErrorTraces: uiErrorTraces,
      parserTrace: parserTrace,
      performanceTrace: performanceTrace,
      networkTrace: networkTrace,
      fallbackTrace: fallbackTrace,
      errorRegistry: errorRegistry,
    );
  }
}
