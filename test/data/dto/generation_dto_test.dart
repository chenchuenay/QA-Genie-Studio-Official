import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/dto/generation_dto.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';

void main() {
  group('GenerationDto', () {
    const dto = GenerationDto(
      module: 'Auth',
      feature: 'Login',
      platform: 'Web',
      mode: GenerationMode.core,
      count: 10,
      traceId: 'trace-001',
    );

    test('constructor sets all fields', () {
      expect(dto.module, 'Auth');
      expect(dto.feature, 'Login');
      expect(dto.platform, 'Web');
      expect(dto.mode, GenerationMode.core);
      expect(dto.count, 10);
      expect(dto.traceId, 'trace-001');
      expect(dto.constraints, '');
      expect(dto.domain, 'general');
      expect(dto.enableSecurityCases, true);
      expect(dto.enableBoundaryCases, true);
      expect(dto.enableUsabilityCases, true);
    });

    test('toJson returns correct map', () {
      final json = dto.toJson();
      expect(json['module'], 'Auth');
      expect(json['feature'], 'Login');
      expect(json['platform'], 'Web');
      expect(json['mode'], 'core');
      expect(json['count'], 10);
      expect(json['traceId'], 'trace-001');
      expect(json['constraints'], '');
      expect(json['domain'], 'general');
      expect(json['enableSecurityCases'], true);
      expect(json['enableBoundaryCases'], true);
      expect(json['enableUsabilityCases'], true);
    });

    test('fromJson reconstructs DTO correctly', () {
      final json = dto.toJson();
      final reconstructed = GenerationDto.fromJson(json);
      expect(reconstructed.module, dto.module);
      expect(reconstructed.feature, dto.feature);
      expect(reconstructed.platform, dto.platform);
      expect(reconstructed.mode, dto.mode);
      expect(reconstructed.count, dto.count);
      expect(reconstructed.traceId, dto.traceId);
      expect(reconstructed.constraints, dto.constraints);
      expect(reconstructed.domain, dto.domain);
      expect(reconstructed.enableSecurityCases, dto.enableSecurityCases);
      expect(reconstructed.enableBoundaryCases, dto.enableBoundaryCases);
      expect(reconstructed.enableUsabilityCases, dto.enableUsabilityCases);
    });

    test('fromJson handles missing fields with defaults', () {
      final reconstructed = GenerationDto.fromJson({});
      expect(reconstructed.module, '');
      expect(reconstructed.feature, '');
      expect(reconstructed.platform, '');
      expect(reconstructed.mode, GenerationMode.core);
      expect(reconstructed.count, 0);
      expect(reconstructed.traceId, '');
      expect(reconstructed.constraints, '');
      expect(reconstructed.domain, 'general');
      expect(reconstructed.enableSecurityCases, false);
      expect(reconstructed.enableBoundaryCases, false);
      expect(reconstructed.enableUsabilityCases, false);
    });

    test('fromJson handles string count', () {
      final reconstructed = GenerationDto.fromJson({'count': '5'});
      expect(reconstructed.count, 0);
    });

    test('copyWith overrides specified fields', () {
      final copy = dto.copyWith(module: 'Payments', count: 20, mode: GenerationMode.pro);
      expect(copy.module, 'Payments');
      expect(copy.count, 20);
      expect(copy.mode, GenerationMode.pro);
      expect(copy.feature, 'Login');
    });

    test('copyWith with no args returns same values', () {
      final copy = dto.copyWith();
      expect(copy.module, dto.module);
      expect(copy.feature, dto.feature);
      expect(copy.platform, dto.platform);
      expect(copy.mode, dto.mode);
      expect(copy.count, dto.count);
    });

    test('toJson trims fields', () {
      final dtoWithSpaces = GenerationDto(
        module: '  Auth  ',
        feature: '  Login  ',
        platform: '  Web  ',
        mode: GenerationMode.core,
        count: 5,
        traceId: '  trace-002  ',
      );
      final json = dtoWithSpaces.toJson();
      expect(json['module'], 'Auth');
      expect(json['feature'], 'Login');
      expect(json['platform'], 'Web');
      expect(json['traceId'], 'trace-002');
    });

    test('toString returns formatted string', () {
      final str = dto.toString();
      expect(str, contains('Auth'));
      expect(str, contains('Login'));
      expect(str, contains('core'));
    });

    test('fromJson with pro mode', () {
      final json = dto.toJson();
      json['mode'] = 'pro';
      final reconstructed = GenerationDto.fromJson(json);
      expect(reconstructed.mode, GenerationMode.pro);
    });
  });
}
