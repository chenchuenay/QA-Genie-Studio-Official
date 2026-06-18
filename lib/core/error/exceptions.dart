// ============================================================
// FILE: lib/core/error/exceptions.dart
// ============================================================

/// ===============================================================
///
/// QA GENIE EXCEPTION HIERARCHY
///
/// PURPOSE:
/// - Centralized deterministic exception system
/// - Production-safe failure categorization
/// - UI-safe error handling
/// - Prevent raw exception leakage
///
/// RULES:
/// - Never throw raw Exception()
/// - Never expose provider internals to UI
/// - Every critical pipeline stage uses typed failures
///
/// ===============================================================
library;

abstract class QaGenieException implements Exception {
  final String message;

  final String code;

  const QaGenieException({required this.message, required this.code});

  /// Whether retrying the operation might succeed.
  /// Network/Server errors are retriable.
  /// Validation, Security, and Quota errors are not.
  bool get isRetriable {
    return switch (code) {
      'NETWORK_ERROR' || 'SERVER_ERROR' || 'API_ERROR' || 'AD_REWARD_ERROR' => true,
      _ => false,
    };
  }

  @override
  String toString() {
    return '$runtimeType($code): $message';
  }
}

typedef AppException = QaGenieException;

// ============================================================
// CONFIGURATION
// ============================================================

class ConfigurationException extends QaGenieException {
  const ConfigurationException(String message)
    : super(message: message, code: 'CONFIGURATION_ERROR');
}

// ============================================================
// NETWORK
// ============================================================

class NetworkException extends QaGenieException {
  const NetworkException(String message)
    : super(message: message, code: 'NETWORK_ERROR');
}

class ApiException extends QaGenieException {
  const ApiException(String message)
    : super(message: message, code: 'API_ERROR');
}

class ServerException extends QaGenieException {
  const ServerException(String message)
    : super(message: message, code: 'SERVER_ERROR');
}

class RateLimitException extends QaGenieException {
  const RateLimitException(String message)
    : super(message: message, code: 'RATE_LIMIT');
}

class UnauthorizedException extends QaGenieException {
  const UnauthorizedException(String message)
    : super(message: message, code: 'UNAUTHORIZED');
}

// ============================================================
// SECURITY
// ============================================================

class SecurityException extends QaGenieException {
  const SecurityException(String message)
    : super(message: message, code: 'SECURITY_ERROR');
}

class AbuseDetectionException extends QaGenieException {
  const AbuseDetectionException(String message)
    : super(message: message, code: 'ABUSE_DETECTED');
}

class PiiViolationException extends QaGenieException {
  const PiiViolationException(String message)
    : super(message: message, code: 'PII_BLOCKED');
}

// ============================================================
// PARSING / VALIDATION
// ============================================================

class ParsingException extends QaGenieException {
  const ParsingException(String message)
    : super(message: message, code: 'PARSING_ERROR');
}

class ValidationException extends QaGenieException {
  const ValidationException(String message)
    : super(message: message, code: 'VALIDATION_ERROR');
}

class StructuralValidationException extends QaGenieException {
  const StructuralValidationException(String message)
    : super(message: message, code: 'STRUCTURAL_VALIDATION_ERROR');
}

class SemanticValidationException extends QaGenieException {
  const SemanticValidationException(String message)
    : super(message: message, code: 'SEMANTIC_VALIDATION_ERROR');
}

class ExportValidationException extends QaGenieException {
  const ExportValidationException(String message)
    : super(message: message, code: 'EXPORT_VALIDATION_ERROR');
}

// ============================================================
// DATABASE
// ============================================================

class DatabaseException extends QaGenieException {
  const DatabaseException(String message)
    : super(message: message, code: 'DATABASE_ERROR');
}

class MigrationException extends QaGenieException {
  const MigrationException(String message)
    : super(message: message, code: 'MIGRATION_ERROR');
}

// ============================================================
// EXPORT
// ============================================================

class ExportException extends QaGenieException {
  const ExportException(String message)
    : super(message: message, code: 'EXPORT_ERROR');
}

class FileWriteException extends QaGenieException {
  const FileWriteException(String message)
    : super(message: message, code: 'FILE_WRITE_ERROR');
}

class ShareException extends QaGenieException {
  const ShareException(String message)
    : super(message: message, code: 'SHARE_ERROR');
}

// ============================================================
// PIPELINE
// ============================================================

class PipelineException extends QaGenieException {
  const PipelineException(String message)
    : super(message: message, code: 'PIPELINE_ERROR');
}

class GenerationException extends QaGenieException {
  const GenerationException(String message)
    : super(message: message, code: 'GENERATION_ERROR');
}

class RepairException extends QaGenieException {
  const RepairException(String message)
    : super(message: message, code: 'REPAIR_ERROR');
}

class FallbackGenerationException extends QaGenieException {
  const FallbackGenerationException(String message)
    : super(message: message, code: 'FALLBACK_GENERATION_ERROR');
}

// ============================================================
// MONETIZATION
// ============================================================

class AdRewardException extends QaGenieException {
  const AdRewardException(String message)
    : super(message: message, code: 'AD_REWARD_ERROR');
}

// ============================================================
// FEATURE FLAGS
// ============================================================

class FeatureDisabledException extends QaGenieException {
  const FeatureDisabledException(String message)
    : super(message: message, code: 'FEATURE_DISABLED');
}

// ============================================================
// FORENSICS
// ============================================================

class AuditLogException extends QaGenieException {
  const AuditLogException(String message)
    : super(message: message, code: 'AUDIT_LOG_ERROR');
}

// ============================================================
// GENERIC SAFE FAILURE
// ============================================================

class UnknownQaGenieException extends QaGenieException {
  const UnknownQaGenieException(String message)
    : super(message: message, code: 'UNKNOWN_ERROR');
}
