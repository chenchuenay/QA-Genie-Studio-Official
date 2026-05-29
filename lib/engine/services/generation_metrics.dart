// ============================================================
// FILE: lib/engine/services/generation_metrics.dart
// ============================================================

/// ===============================================================
///
/// GENERATION METRICS
///
/// PURPOSE:
/// - Pipeline observability
/// - Failure analysis
/// - AI cost monitoring
/// - Performance tracking
/// - Repair visibility
/// - Production telemetry
///
/// IMPORTANT:
/// This class MUST remain immutable.
///
/// ===============================================================
class GenerationMetrics {
  // ============================================================
  // CORE COUNTS
  // ============================================================

  final int requestedCount;

  final int generatedCount;

  final int finalizedCount;

  final int rejectedCount;

  final int repairedCount;

  final int fallbackCount;

  final int emergencyRecoveredCount;

  // ============================================================
  // VALIDATION COUNTS
  // ============================================================

  final int structuralRejected;

  final int semanticRejected;

  final int realismRejected;

  final int exportSafetyRejected;

  // ============================================================
  // TIMING METRICS
  // ============================================================

  final int totalDurationMs;

  final int aiLatencyMs;

  final int validationLatencyMs;

  final int repairLatencyMs;

  final int exportSafetyLatencyMs;

  // ============================================================
  // TOKEN + COST VISIBILITY
  // ============================================================

  final int estimatedPromptTokens;

  final int estimatedCompletionTokens;

  final int estimatedTotalTokens;

  // ============================================================
  // PIPELINE HEALTH
  // ============================================================

  final bool usedFallback;

  final bool usedEmergencyRecovery;

  final bool generationSuccessful;

  final double averageConfidenceScore;

  // ============================================================
  // FORENSIC
  // ============================================================

  final String traceId;

  final DateTime generatedAt;

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const GenerationMetrics({
    required this.requestedCount,
    required this.generatedCount,
    required this.finalizedCount,
    required this.rejectedCount,
    required this.repairedCount,
    required this.fallbackCount,
    required this.emergencyRecoveredCount,
    required this.structuralRejected,
    required this.semanticRejected,
    required this.realismRejected,
    required this.exportSafetyRejected,
    required this.totalDurationMs,
    this.aiLatencyMs = 0,
    this.validationLatencyMs = 0,
    this.repairLatencyMs = 0,
    this.exportSafetyLatencyMs = 0,
    this.estimatedPromptTokens = 0,
    this.estimatedCompletionTokens = 0,
    this.estimatedTotalTokens = 0,
    required this.usedFallback,
    this.usedEmergencyRecovery = false,
    required this.generationSuccessful,
    this.averageConfidenceScore = 0.0,
    required this.traceId,
    required this.generatedAt,
  });

  // ============================================================
  // EMPTY
  // ============================================================

  factory GenerationMetrics.empty() {
    return GenerationMetrics(
      requestedCount: 0,
      generatedCount: 0,
      finalizedCount: 0,
      rejectedCount: 0,
      repairedCount: 0,
      fallbackCount: 0,
      emergencyRecoveredCount: 0,
      structuralRejected: 0,
      semanticRejected: 0,
      realismRejected: 0,
      exportSafetyRejected: 0,
      totalDurationMs: 0,
      aiLatencyMs: 0,
      validationLatencyMs: 0,
      repairLatencyMs: 0,
      exportSafetyLatencyMs: 0,
      estimatedPromptTokens: 0,
      estimatedCompletionTokens: 0,
      estimatedTotalTokens: 0,
      usedFallback: false,
      usedEmergencyRecovery: false,
      generationSuccessful: false,
      averageConfidenceScore: 0.0,
      traceId: '',
      generatedAt: DateTime.now(),
    );
  }

  // ============================================================
  // FAILURE
  // ============================================================

  factory GenerationMetrics.failed({String traceId = ''}) {
    return GenerationMetrics(
      requestedCount: 0,
      generatedCount: 0,
      finalizedCount: 0,
      rejectedCount: 0,
      repairedCount: 0,
      fallbackCount: 0,
      emergencyRecoveredCount: 0,
      structuralRejected: 0,
      semanticRejected: 0,
      realismRejected: 0,
      exportSafetyRejected: 0,
      totalDurationMs: 0,
      aiLatencyMs: 0,
      validationLatencyMs: 0,
      repairLatencyMs: 0,
      exportSafetyLatencyMs: 0,
      estimatedPromptTokens: 0,
      estimatedCompletionTokens: 0,
      estimatedTotalTokens: 0,
      usedFallback: false,
      usedEmergencyRecovery: false,
      generationSuccessful: false,
      averageConfidenceScore: 0.0,
      traceId: traceId,
      generatedAt: DateTime.now(),
    );
  }

  // ============================================================
  // DERIVED HEALTH
  // ============================================================

  double get successRate {
    if (requestedCount == 0) {
      return 0;
    }

    return finalizedCount / requestedCount;
  }

  double get rejectionRate {
    if (generatedCount == 0) {
      return 0;
    }

    return rejectedCount / generatedCount;
  }

  bool get isHealthy {
    return generationSuccessful && finalizedCount > 0 && rejectionRate < 0.5;
  }

  bool get hasSevereRejection {
    return rejectionRate >= 0.7;
  }

  // ============================================================
  // TOKEN ESTIMATION
  // ============================================================

  static int estimateTokens(String text) {
    if (text.trim().isEmpty) {
      return 0;
    }

    return (text.length / 4).ceil();
  }

  // ============================================================
  // COPY
  // ============================================================

  GenerationMetrics copyWith({
    int? requestedCount,
    int? generatedCount,
    int? finalizedCount,
    int? rejectedCount,
    int? repairedCount,
    int? fallbackCount,
    int? emergencyRecoveredCount,
    int? structuralRejected,
    int? semanticRejected,
    int? realismRejected,
    int? exportSafetyRejected,
    int? totalDurationMs,
    int? aiLatencyMs,
    int? validationLatencyMs,
    int? repairLatencyMs,
    int? exportSafetyLatencyMs,
    int? estimatedPromptTokens,
    int? estimatedCompletionTokens,
    int? estimatedTotalTokens,
    bool? usedFallback,
    bool? usedEmergencyRecovery,
    bool? generationSuccessful,
    double? averageConfidenceScore,
    String? traceId,
    DateTime? generatedAt,
  }) {
    return GenerationMetrics(
      requestedCount: requestedCount ?? this.requestedCount,
      generatedCount: generatedCount ?? this.generatedCount,
      finalizedCount: finalizedCount ?? this.finalizedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      repairedCount: repairedCount ?? this.repairedCount,
      fallbackCount: fallbackCount ?? this.fallbackCount,
      emergencyRecoveredCount:
          emergencyRecoveredCount ?? this.emergencyRecoveredCount,
      structuralRejected: structuralRejected ?? this.structuralRejected,
      semanticRejected: semanticRejected ?? this.semanticRejected,
      realismRejected: realismRejected ?? this.realismRejected,
      exportSafetyRejected: exportSafetyRejected ?? this.exportSafetyRejected,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      aiLatencyMs: aiLatencyMs ?? this.aiLatencyMs,
      validationLatencyMs: validationLatencyMs ?? this.validationLatencyMs,
      repairLatencyMs: repairLatencyMs ?? this.repairLatencyMs,
      exportSafetyLatencyMs:
          exportSafetyLatencyMs ?? this.exportSafetyLatencyMs,
      estimatedPromptTokens:
          estimatedPromptTokens ?? this.estimatedPromptTokens,
      estimatedCompletionTokens:
          estimatedCompletionTokens ?? this.estimatedCompletionTokens,
      estimatedTotalTokens: estimatedTotalTokens ?? this.estimatedTotalTokens,
      usedFallback: usedFallback ?? this.usedFallback,
      usedEmergencyRecovery:
          usedEmergencyRecovery ?? this.usedEmergencyRecovery,
      generationSuccessful: generationSuccessful ?? this.generationSuccessful,
      averageConfidenceScore:
          averageConfidenceScore ?? this.averageConfidenceScore,
      traceId: traceId ?? this.traceId,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  // ============================================================
  // JSON
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'requestedCount': requestedCount,
      'generatedCount': generatedCount,
      'finalizedCount': finalizedCount,
      'rejectedCount': rejectedCount,
      'repairedCount': repairedCount,
      'fallbackCount': fallbackCount,
      'emergencyRecoveredCount': emergencyRecoveredCount,
      'structuralRejected': structuralRejected,
      'semanticRejected': semanticRejected,
      'realismRejected': realismRejected,
      'exportSafetyRejected': exportSafetyRejected,
      'totalDurationMs': totalDurationMs,
      'aiLatencyMs': aiLatencyMs,
      'validationLatencyMs': validationLatencyMs,
      'repairLatencyMs': repairLatencyMs,
      'exportSafetyLatencyMs': exportSafetyLatencyMs,
      'estimatedPromptTokens': estimatedPromptTokens,
      'estimatedCompletionTokens': estimatedCompletionTokens,
      'estimatedTotalTokens': estimatedTotalTokens,
      'usedFallback': usedFallback,
      'usedEmergencyRecovery': usedEmergencyRecovery,
      'generationSuccessful': generationSuccessful,
      'averageConfidenceScore': averageConfidenceScore,
      'traceId': traceId,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory GenerationMetrics.fromJson(Map<String, dynamic> json) {
    return GenerationMetrics(
      requestedCount: json['requestedCount'] ?? 0,
      generatedCount: json['generatedCount'] ?? 0,
      finalizedCount: json['finalizedCount'] ?? 0,
      rejectedCount: json['rejectedCount'] ?? 0,
      repairedCount: json['repairedCount'] ?? 0,
      fallbackCount: json['fallbackCount'] ?? 0,
      emergencyRecoveredCount: json['emergencyRecoveredCount'] ?? 0,
      structuralRejected: json['structuralRejected'] ?? 0,
      semanticRejected: json['semanticRejected'] ?? 0,
      realismRejected: json['realismRejected'] ?? 0,
      exportSafetyRejected: json['exportSafetyRejected'] ?? 0,
      totalDurationMs: json['totalDurationMs'] ?? 0,
      aiLatencyMs: json['aiLatencyMs'] ?? 0,
      validationLatencyMs: json['validationLatencyMs'] ?? 0,
      repairLatencyMs: json['repairLatencyMs'] ?? 0,
      exportSafetyLatencyMs: json['exportSafetyLatencyMs'] ?? 0,
      estimatedPromptTokens: json['estimatedPromptTokens'] ?? 0,
      estimatedCompletionTokens: json['estimatedCompletionTokens'] ?? 0,
      estimatedTotalTokens: json['estimatedTotalTokens'] ?? 0,
      usedFallback: json['usedFallback'] ?? false,
      usedEmergencyRecovery: json['usedEmergencyRecovery'] ?? false,
      generationSuccessful: json['generationSuccessful'] ?? false,
      averageConfidenceScore: (json['averageConfidenceScore'] ?? 0.0)
          .toDouble(),
      traceId: json['traceId'] ?? '',
      generatedAt:
          DateTime.tryParse(json['generatedAt'] ?? '') ?? DateTime.now(),
    );
  }
}
