import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/platform_utils.dart';

void main() {
  group('PlatformUtils.normalize', () {
    test('maps web variants to Web', () {
      expect(PlatformUtils.normalize('web'), 'Web');
      expect(PlatformUtils.normalize('website'), 'Web');
      expect(PlatformUtils.normalize('browser'), 'Web');
    });

    test('maps mobile variants to Mobile', () {
      expect(PlatformUtils.normalize('mobile'), 'Mobile');
      expect(PlatformUtils.normalize('android'), 'Mobile');
      expect(PlatformUtils.normalize('ios'), 'Mobile');
      expect(PlatformUtils.normalize('app'), 'Mobile');
    });

    test('maps API variants to API', () {
      expect(PlatformUtils.normalize('api'), 'API');
      expect(PlatformUtils.normalize('backend'), 'API');
      expect(PlatformUtils.normalize('rest'), 'API');
      expect(PlatformUtils.normalize('graphql'), 'API');
    });

    test('defaults to Web for unknown', () {
      expect(PlatformUtils.normalize('desktop'), 'Web');
      expect(PlatformUtils.normalize(''), 'Web');
    });
  });

  group('PlatformUtils checkers', () {
    test('isWeb', () {
      expect(PlatformUtils.isWeb('web'), true);
      expect(PlatformUtils.isWeb('mobile'), false);
    });

    test('isMobile', () {
      expect(PlatformUtils.isMobile('android'), true);
      expect(PlatformUtils.isMobile('web'), false);
    });

    test('isApi', () {
      expect(PlatformUtils.isApi('api'), true);
      expect(PlatformUtils.isApi('web'), false);
    });
  });

  group('PlatformUtils.apiEndpoint', () {
    test('generates correct endpoint', () {
      expect(PlatformUtils.apiEndpoint('Login'), '/api/v1/login');
      expect(PlatformUtils.apiEndpoint('User Authentication'), '/api/v1/user-authentication');
    });
  });

  group('PlatformUtils.displayPrefix', () {
    test('returns correct prefix', () {
      expect(PlatformUtils.displayPrefix('api'), '[API]');
      expect(PlatformUtils.displayPrefix('mobile'), '[MOBILE]');
      expect(PlatformUtils.displayPrefix('web'), '[WEB]');
      expect(PlatformUtils.displayPrefix('unknown'), '[WEB]');
    });
  });
}
