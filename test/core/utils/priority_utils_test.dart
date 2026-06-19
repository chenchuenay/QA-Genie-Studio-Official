import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/core/utils/priority_utils.dart';

void main() {
  group('PriorityUtils.normalize', () {
    test('returns Medium for null', () {
      expect(PriorityUtils.normalize(null), 'Medium');
    });

    test('returns Medium for empty string', () {
      expect(PriorityUtils.normalize(''), 'Medium');
      expect(PriorityUtils.normalize('   '), 'Medium');
    });

    group('maps to High', () {
      for (final input in ['high', 'critical', 'p0', 'highest', 'blocker', 'sev1', '1']) {
        test('"$input" → High', () {
          expect(PriorityUtils.normalize(input), 'High');
        });
      }
    });

    group('maps to Medium', () {
      for (final input in ['medium', 'moderate', 'major', 'p1', '2']) {
        test('"$input" → Medium', () {
          expect(PriorityUtils.normalize(input), 'Medium');
        });
      }
    });

    group('maps to Low', () {
      for (final input in ['low', 'minor', 'trivial', 'p2', '3']) {
        test('"$input" → Low', () {
          expect(PriorityUtils.normalize(input), 'Low');
        });
      }
    });

    test('returns Medium for unknown value', () {
      expect(PriorityUtils.normalize('unknown'), 'Medium');
    });
  });

  group('PriorityUtils.fallback', () {
    test('returns High for security keywords', () {
      expect(PriorityUtils.fallback(category: '', title: 'SQL injection test', feature: ''), 'High');
      expect(PriorityUtils.fallback(category: '', title: '', feature: 'payment processing'), 'High');
      expect(PriorityUtils.fallback(category: '', title: '', feature: 'auth token refresh'), 'High');
    });

    test('returns Medium for validation keywords', () {
      expect(PriorityUtils.fallback(category: 'validation', title: '', feature: ''), 'Medium');
      expect(PriorityUtils.fallback(category: '', title: 'boundary test', feature: ''), 'Medium');
    });

    test('returns Low for other content', () {
      expect(PriorityUtils.fallback(category: 'positive', title: 'happy path', feature: 'view profile'), 'Low');
    });
  });

  group('PriorityConstants', () {
    test('has correct values', () {
      expect(PriorityConstants.high, 'High');
      expect(PriorityConstants.medium, 'Medium');
      expect(PriorityConstants.low, 'Low');
    });

    test('all contains three priorities', () {
      expect(PriorityConstants.all, ['High', 'Medium', 'Low']);
    });
  });
}
