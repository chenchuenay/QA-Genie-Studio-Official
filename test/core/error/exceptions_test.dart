import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/error/exceptions.dart';

void main() {
  group('QaGenieException', () {
    test('stores message and code', () {
      final ex = NetworkException('Connection failed');
      expect(ex.message, 'Connection failed');
      expect(ex.code, 'NETWORK_ERROR');
    });

    test('toString includes code and message', () {
      final ex = NetworkException('Timeout');
      expect(ex.toString(), contains('NETWORK_ERROR'));
      expect(ex.toString(), contains('Timeout'));
    });
  });

  group('isRetriable', () {
    test('NETWORK_ERROR is retriable', () {
      expect(NetworkException('msg').isRetriable, true);
    });

    test('SERVER_ERROR is retriable', () {
      expect(ServerException('msg').isRetriable, true);
    });

    test('API_ERROR is retriable', () {
      expect(ApiException('msg').isRetriable, true);
    });

    test('AD_REWARD_ERROR is retriable', () {
      expect(AdRewardException('msg').isRetriable, true);
    });

    test('SECURITY_ERROR is not retriable', () {
      expect(SecurityException('msg').isRetriable, false);
    });

    test('VALIDATION_ERROR is not retriable', () {
      expect(ValidationException('msg').isRetriable, false);
    });

    test('QUOTA error is not retriable', () {
      expect(RateLimitException('msg').isRetriable, false);
    });
  });

  group('All exception types', () {
    test('ConfigurationException', () {
      expect(ConfigurationException('bad config').code, 'CONFIGURATION_ERROR');
    });

    test('NetworkException', () {
      expect(NetworkException('').code, 'NETWORK_ERROR');
    });

    test('ApiException', () {
      expect(ApiException('').code, 'API_ERROR');
    });

    test('ServerException', () {
      expect(ServerException('').code, 'SERVER_ERROR');
    });

    test('RateLimitException', () {
      expect(RateLimitException('').code, 'RATE_LIMIT');
    });

    test('UnauthorizedException', () {
      expect(UnauthorizedException('').code, 'UNAUTHORIZED');
    });

    test('SecurityException', () {
      expect(SecurityException('').code, 'SECURITY_ERROR');
    });

    test('AbuseDetectionException', () {
      expect(AbuseDetectionException('').code, 'ABUSE_DETECTED');
    });

    test('PiiViolationException', () {
      expect(PiiViolationException('').code, 'PII_BLOCKED');
    });

    test('ParsingException', () {
      expect(ParsingException('').code, 'PARSING_ERROR');
    });

    test('ValidationException', () {
      expect(ValidationException('').code, 'VALIDATION_ERROR');
    });

    test('StructuralValidationException', () {
      expect(StructuralValidationException('').code, 'STRUCTURAL_VALIDATION_ERROR');
    });

    test('SemanticValidationException', () {
      expect(SemanticValidationException('').code, 'SEMANTIC_VALIDATION_ERROR');
    });

    test('ExportValidationException', () {
      expect(ExportValidationException('').code, 'EXPORT_VALIDATION_ERROR');
    });

    test('DatabaseException', () {
      expect(DatabaseException('').code, 'DATABASE_ERROR');
    });

    test('MigrationException', () {
      expect(MigrationException('').code, 'MIGRATION_ERROR');
    });

    test('ExportException', () {
      expect(ExportException('').code, 'EXPORT_ERROR');
    });

    test('FileWriteException', () {
      expect(FileWriteException('').code, 'FILE_WRITE_ERROR');
    });

    test('ShareException', () {
      expect(ShareException('').code, 'SHARE_ERROR');
    });

    test('PipelineException', () {
      expect(PipelineException('').code, 'PIPELINE_ERROR');
    });

    test('GenerationException', () {
      expect(GenerationException('').code, 'GENERATION_ERROR');
    });

    test('RepairException', () {
      expect(RepairException('').code, 'REPAIR_ERROR');
    });

    test('FallbackGenerationException', () {
      expect(FallbackGenerationException('').code, 'FALLBACK_GENERATION_ERROR');
    });

    test('AdRewardException', () {
      expect(AdRewardException('').code, 'AD_REWARD_ERROR');
    });

    test('FeatureDisabledException', () {
      expect(FeatureDisabledException('').code, 'FEATURE_DISABLED');
    });

    test('AuditLogException', () {
      expect(AuditLogException('').code, 'AUDIT_LOG_ERROR');
    });

    test('UnknownQaGenieException', () {
      expect(UnknownQaGenieException('').code, 'UNKNOWN_ERROR');
    });
  });
}
