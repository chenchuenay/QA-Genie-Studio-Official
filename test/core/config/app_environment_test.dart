import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/config/app_environment.dart';

void main() {
  group('EnvironmentAuthority', () {
    test('isDev and isProduction are consistent', () {
      expect(EnvironmentAuthority.isDev, isNot(EnvironmentAuthority.isProduction));
    });

    test('isDev returns false in test environment (default prod)', () {
      expect(EnvironmentAuthority.isDev, false);
    });

    test('isProd returns true in test environment', () {
      expect(EnvironmentAuthority.isProd, true);
    });

    test('diagnostics returns map with all keys', () {
      final diag = EnvironmentAuthority.diagnostics();
      expect(diag, containsPair('environment', 'PROD'));
      expect(diag.keys, contains('requireCloudAuthority'));
      expect(diag.keys, contains('requireAppCheck'));
      expect(diag.keys, contains('requirePiiScrubbing'));
    });

    test('security flags are strict in prod', () {
      expect(EnvironmentAuthority.requireCloudAuthority, true);
      expect(EnvironmentAuthority.requireAppCheck, true);
      expect(EnvironmentAuthority.requireSignedTokens, true);
    });

    test('allow flags are false in prod', () {
      expect(EnvironmentAuthority.allowDebugLogs, false);
      expect(EnvironmentAuthority.allowMockAds, false);
    });
  });
}
