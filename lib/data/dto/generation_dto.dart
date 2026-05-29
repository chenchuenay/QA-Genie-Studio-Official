import 'package:qa_genie/domain/enums/generation_mode.dart';
// ============================================================
// FILE: lib/data/dto/generation_dto.dart
// ============================================================


/// ===============================================================
///
/// GENERATION DTO
///
/// PURPOSE:
/// - immutable transport object
/// - request payload for AI generation
/// - used between:
///     UI -> Repository -> Remote Source
///
/// RULES:
/// - no business logic
/// - no validation logic
/// - no parsing side-effects
/// - transport-safe only
///
/// ===============================================================
class GenerationDto {
  final String module;

  final String feature;

  final String platform;

  final GenerationMode mode;

  final int count;

  final String constraints;

  final String domain;

  final String traceId;

  final bool enableSecurityCases;

  final bool enableBoundaryCases;

  final bool enableUsabilityCases;

  const GenerationDto({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    required this.traceId,

    this.constraints = '',

    this.domain = 'general',

    this.enableSecurityCases = true,

    this.enableBoundaryCases = true,

    this.enableUsabilityCases = true,
  });

  // ============================================================
  // SERIALIZATION
  // ============================================================

  Map<String, dynamic> toJson() {
    return {
      'module': module.trim(),

      'feature': feature.trim(),

      'platform': platform.trim(),

      'mode': mode.name,

      'count': count,

      'constraints': constraints.trim(),

      'domain': domain.trim(),

      'traceId': traceId.trim(),

      'enableSecurityCases': enableSecurityCases,

      'enableBoundaryCases': enableBoundaryCases,

      'enableUsabilityCases': enableUsabilityCases,
    };
  }

  // ============================================================
  // DESERIALIZATION
  // ============================================================

  factory GenerationDto.fromJson(Map<String, dynamic> json) {
    return GenerationDto(
      module: (json['module'] ?? '').toString(),

      feature: (json['feature'] ?? '').toString(),

      platform: (json['platform'] ?? '').toString(),

      mode: GenerationMode.values.firstWhere(
        (e) => e.name == json['mode'],
        orElse: () => GenerationMode.core,
      ),

      count: json['count'] is int ? json['count'] as int : 0,

      constraints: (json['constraints'] ?? '').toString(),

      domain: (json['domain'] ?? 'general').toString(),

      traceId: (json['traceId'] ?? '').toString(),

      enableSecurityCases: json['enableSecurityCases'] == true,

      enableBoundaryCases: json['enableBoundaryCases'] == true,

      enableUsabilityCases: json['enableUsabilityCases'] == true,
    );
  }

  // ============================================================
  // COPY
  // ============================================================

  GenerationDto copyWith({
    String? module,
    String? feature,
    String? platform,
    GenerationMode? mode,
    int? count,
    String? constraints,
    String? domain,
    String? traceId,
    bool? enableSecurityCases,
    bool? enableBoundaryCases,
    bool? enableUsabilityCases,
  }) {
    return GenerationDto(
      module: module ?? this.module,

      feature: feature ?? this.feature,

      platform: platform ?? this.platform,

      mode: mode ?? this.mode,

      count: count ?? this.count,

      constraints: constraints ?? this.constraints,

      domain: domain ?? this.domain,

      traceId: traceId ?? this.traceId,

      enableSecurityCases: enableSecurityCases ?? this.enableSecurityCases,

      enableBoundaryCases: enableBoundaryCases ?? this.enableBoundaryCases,

      enableUsabilityCases: enableUsabilityCases ?? this.enableUsabilityCases,
    );
  }

  // ============================================================
  // DEBUG
  // ============================================================

  @override
  String toString() {
    return '''
GenerationDto(
  module: $module,
  feature: $feature,
  platform: $platform,
  mode: ${mode.name},
  count: $count,
  domain: $domain,
  traceId: $traceId
)
''';
  }
}
