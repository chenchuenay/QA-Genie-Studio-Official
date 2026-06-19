import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/security/pii_scrubber.dart';

void main() {
  group('PIIScrubber.scrub', () {
    test('returns empty input unchanged', () {
      expect(PIIScrubber.scrub(''), '');
      expect(PIIScrubber.scrub('   '), '   ');
    });

    test('scrubs email addresses', () {
      final result = PIIScrubber.scrub('Contact admin@example.com for help');
      expect(result, contains('[REDACTED_EMAIL]'));
      expect(result, isNot(contains('admin@example.com')));
    });

    test('scrubs phone numbers', () {
      final result = PIIScrubber.scrub('Call +1-555-123-4567 now');
      expect(result, contains('[REDACTED_PHONE]'));
    });

    test('scrubs URLs', () {
      final result = PIIScrubber.scrub('Visit https://example.com/login');
      expect(result, contains('[REDACTED_URL]'));
    });

    test('scrubs IP addresses', () {
      final result = PIIScrubber.scrub('Server IP: 192.168.1.1');
      expect(result, contains('[REDACTED_IP]'));
    });

    test('scrubs JWT tokens', () {
      final result = PIIScrubber.scrub('eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0In0.dGVzdA');
      expect(result, contains('[REDACTED_JWT]'));
    });

    test('scrubs UUIDs', () => expect(
      PIIScrubber.scrub('uuid: 550e8400-e29b-41d4-a716-446655440000'),
      contains('[REDACTED_UUID]'),
    ));

    test('scrubs API keys', () {
      expect(PIIScrubber.scrub('key=sk_live_abc123xyz'), contains('[REDACTED_API_KEY]'));
    });

    test('scrubs credit card numbers with Luhn check', () {
      expect(PIIScrubber.scrub('4111111111111111'), contains('[REDACTED_CARD]'));
    });

    test('normalizes whitespace', () {
      final result = PIIScrubber.scrub('hello    world');
      expect(result, 'hello world');
    });
  });

  group('PIIScrubber.containsSensitiveData', () {
    test('returns true when email present', () => expect(PIIScrubber.containsSensitiveData('user@domain.com'), true));
    test('returns false for clean text', () => expect(PIIScrubber.containsSensitiveData('hello world'), false));
  });

  group('PIIScrubber.detect', () {
    test('detects email', () => expect(PIIScrubber.detect('a@b.com'), contains('email')));
    test('detects phone', () => expect(PIIScrubber.detect('+1234567890'), contains('phone')));
    test('detects ip', () => expect(PIIScrubber.detect('10.0.0.1'), contains('ip')));
    test('detects url', () => expect(PIIScrubber.detect('https://x.com'), contains('url')));
    test('detects multiple finding types', () {
      final findings = PIIScrubber.detect('user@x.com +1234567890');
      expect(findings, contains('email'));
      expect(findings, contains('phone'));
    });
    test('returns empty for clean text', () => expect(PIIScrubber.detect('clean text'), isEmpty));
  });
}
