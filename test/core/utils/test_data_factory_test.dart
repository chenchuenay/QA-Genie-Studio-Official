import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/test_data_factory.dart';

void main() {
  group('TestDataFactory emails', () {
    test('validEmail returns deterministic value with seed', () {
      expect(TestDataFactory.validEmail('test'), TestDataFactory.validEmail('test'));
    });

    test('validEmail returns max 25 chars', () {
      final email = TestDataFactory.validEmail();
      expect(email.length, lessThanOrEqualTo(25));
    });

    test('emailUpper uppercases', () {
      final upper = TestDataFactory.emailUpper('test');
      expect(upper, upper.toUpperCase());
    });
  });

  group('TestDataFactory passwords', () {
    test('validPassword is deterministic', () {
      expect(TestDataFactory.validPassword('x'), TestDataFactory.validPassword('x'));
    });

    test('validPassword is max 25 chars', () {
      expect(TestDataFactory.validPassword().length, lessThanOrEqualTo(25));
    });
  });

  group('TestDataFactory reference', () {
    test('produces REF-XXXX format', () {
      final ref = TestDataFactory.reference('test');
      expect(ref, matches(RegExp(r'^REF-\d+$')));
    });

    test('is deterministic', () {
      expect(TestDataFactory.reference('abc'), TestDataFactory.reference('abc'));
    });
  });

  group('TestDataFactory.isSafeInput', () {
    test('safe inputs pass', () {
      expect(TestDataFactory.isSafeInput('hello'), true);
      expect(TestDataFactory.isSafeInput('user@test.com'), true);
    });

    test('blocks >25 char input', () {
      expect(TestDataFactory.isSafeInput('a' * 26), false);
    });

    test('blocks repetitive patterns', () {
      expect(TestDataFactory.isSafeInput('aaaaaaa'), false);
    });

    test('blocks real domains', () {
      expect(TestDataFactory.isSafeInput('user@gmail.com'), false);
      expect(TestDataFactory.isSafeInput('test@yahoo.com'), false);
    });
  });

  group('TestDataFactory static values', () {
    test('returns predefined values without throwing', () {
      expect(TestDataFactory.validOtp(), '123456');
      expect(TestDataFactory.providerGoogle(), 'google');
      expect(TestDataFactory.sqlInjection(), "'OR 1=1");
      expect(TestDataFactory.xssPayload(), '<script>');
      expect(TestDataFactory.cardValid(), 'card_valid');
      expect(TestDataFactory.sessionExpired(), 'session_expired');
      expect(TestDataFactory.appointmentValid(), 'appt_valid');
    });
  });
}
