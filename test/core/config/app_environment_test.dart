import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/config/app_environment.dart';

void main() {
  group('EnvironmentAuthority', () {
    test('isDev and isProduction are consistent', () {
      expect(EnvironmentAuthority.isDev, isNot(EnvironmentAuthority.isProduction));
    });

    test('isDev returns true in test environment (default dev)', () {
      expect(EnvironmentAuthority.isDev, true);
    });

    test('isProd returns false in test environment', () {
      expect(EnvironmentAuthority.isProd, false);
    });

    test('diagnostics returns map with all keys', () {
      final diag = EnvironmentAuthority.diagnostics();
      expect(diag, containsPair('environment', 'DEV'));
      expect(diag.keys, contains('requireCloudAuthority'));
      expect(diag.keys, contains('requireAppCheck'));
      expect(diag.keys, contains('requirePiiScrubbing'));
    });

    test('security flags are relaxed in dev', () {
      expect(EnvironmentAuthority.requireCloudAuthority, false);
      expect(EnvironmentAuthority.requireAppCheck, false);
      expect(EnvironmentAuthority.requireSignedTokens, false);
    });

    test('allow flags are true in dev', () {
      expect(EnvironmentAuthority.allowDebugLogs, true);
      expect(EnvironmentAuthority.allowMockAds, false);
    });
  });
}
