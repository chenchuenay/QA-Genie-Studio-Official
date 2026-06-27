import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/network/network_guard.dart';

void main() {
  setUp(() {
    NetworkGuard.dispose();
  });

  group('NetworkGuard', () {
    test('isOnline returns false initially', () {
      expect(NetworkGuard.isOnline, false);
    });

    test('onlineStatus is false initially', () {
      expect(NetworkGuard.onlineStatus.value, false);
    });

    test('dispose does not throw', () {
      expect(() => NetworkGuard.dispose(), returnsNormally);
    });

    test('isProduction returns true in test environment (default prod)', () {
      expect(NetworkGuard.isProduction, true);
    });
  });
}
