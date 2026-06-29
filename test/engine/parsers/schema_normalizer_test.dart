import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/parsers/schema_normalizer.dart';

void main() {
  group('SchemaNormalizer', () {
    late SchemaNormalizer normalizer;

    setUp(() {
      normalizer = const SchemaNormalizer();
    });

    group('normalizeCase', () {
      test('maps all fields correctly', () {
        final result = normalizer.normalizeCase({
          'title': 'Login Test',
          'module': 'Auth',
          'feature': 'Login',
          'platform': 'Android',
          'priority': 'high',
          'type': '',
          'categoryLock': 'positive',
          'preconditions': ['User is logged in'],
          'testData': 'valid@email.com',
          'steps': [
            {'action': 'Enter email', 'expected': 'Field accepts input'},
          ],
          'expectedResult': 'User is logged in',
          'actualResult': '',
          'status': 'Not Executed',
          'id': 'TC-001',
          'constraints': 'only positive',
          'intent_id': 'login_valid',
        });
        expect(result['id'], 'TC-001');
        expect(result['title'], 'Login Test');
        expect(result['module'], 'Auth');
        expect(result['feature'], 'Login');
        expect(result['platform'], 'Android');
        expect(result['priority'], 'High');
        expect(result['type'], '');
        expect(result['categoryLock'], 'positive');
        expect(result['preconditions'], ['User is logged in']);
        expect(result['testData'], 'valid@email.com');
        expect(result['steps'], hasLength(1));
        expect(result['steps'].first['action'], 'Enter email');
        expect(result['expectedResult'], 'User is logged in');
        expect(result['actualResult'], '');
        expect(result['status'], 'Not Executed');
        expect(result['constraints'], 'only positive');
        expect(result['intent_id'], 'login_valid');
      });

      test('resolves alias field names', () {
        final result = normalizer.normalizeCase({
          'test_case_title': 'Alias Title',
          'test_case_id': 'TC-002',
          'test_case_name': 'ignored',
          'moduleName': 'Billing',
          'featureName': 'Payment',
          'targetPlatform': 'iOS',
          'test_type': 'Regression',
          'expected_results': 'Works',
          'actual_result': 'Pending',
        });
        expect(result['id'], 'TC-002');
        expect(result['title'], 'Alias Title');
        expect(result['module'], 'Billing');
        expect(result['feature'], 'Payment');
        expect(result['platform'], 'iOS');
        expect(result['type'], 'Regression');
        expect(result['expectedResult'], 'Works');
        expect(result['actualResult'], 'Pending');
      });

      test('provides defaults for missing fields', () {
        final result = normalizer.normalizeCase({});
        expect(result['id'], '');
        expect(result['title'], '');
        expect(result['module'], '');
        expect(result['feature'], '');
        expect(result['platform'], '');
        expect(result['priority'], 'Medium');
        expect(result['type'], '');
        expect(result['categoryLock'], 'positive');
        expect(result['preconditions'], isEmpty);
        expect(result['testData'], '');
        expect(result['steps'], isEmpty);
        expect(result['expectedResult'], '');
        expect(result['actualResult'], '');
        expect(result['status'], 'Not Executed');
        expect(result['constraints'], '');
        expect(result['intent_id'], '');
      });

      test('normalizes priority correctly', () {
        expect(normalizer.normalizeCase({'priority': 'critical'})['priority'], 'Critical');
        expect(normalizer.normalizeCase({'priority': 'High'})['priority'], 'High');
        expect(normalizer.normalizeCase({'priority': 'medium'})['priority'], 'Medium');
        expect(normalizer.normalizeCase({'priority': 'LOW'})['priority'], 'Low');
        expect(normalizer.normalizeCase({'priority': 'unknown'})['priority'], 'Medium');
        expect(normalizer.normalizeCase({})['priority'], 'Medium');
      });

      test('normalizes type with empty fallback', () {
        expect(normalizer.normalizeCase({})['type'], '');
        expect(normalizer.normalizeCase({'type': ''})['type'], '');
        expect(normalizer.normalizeCase({'type': 'Smoke'})['type'], 'Smoke');
      });

      test('normalizes category correctly', () {
        expect(normalizer.normalizeCase({'categoryLock': 'Positive Test'})['categoryLock'], 'positive');
        expect(normalizer.normalizeCase({'categoryLock': 'NEGATIVE'})['categoryLock'], 'negative');
        expect(normalizer.normalizeCase({'categoryLock': 'Boundary'})['categoryLock'], 'boundary');
        expect(normalizer.normalizeCase({'categoryLock': 'edge case'})['categoryLock'], 'edge');
        expect(normalizer.normalizeCase({'categoryLock': 'security test'})['categoryLock'], 'security');
        expect(normalizer.normalizeCase({'categoryLock': 'session mgmt'})['categoryLock'], 'session');
        expect(normalizer.normalizeCase({'categoryLock': 'validation'})['categoryLock'], 'validation');
        expect(normalizer.normalizeCase({'categoryLock': 'accessibility'})['categoryLock'], 'accessibility');
        expect(normalizer.normalizeCase({'categoryLock': 'performance'})['categoryLock'], 'performance');
        expect(normalizer.normalizeCase({'categoryLock': ''})['categoryLock'], 'positive');
        expect(normalizer.normalizeCase({'categoryLock': 'custom'})['categoryLock'], 'custom');
      });

      test('normalizes category via category alias', () {
        final result = normalizer.normalizeCase({'category': 'Security Test'});
        expect(result['categoryLock'], 'security');
      });

      test('normalizes steps with string entries', () {
        final result = normalizer.normalizeCase({
          'title': 'T',
          'steps': ['Do step 1', 'Do step 2'],
        });
        expect(result['steps'], hasLength(2));
        expect(result['steps'][0]['action'], 'Do step 1');
        expect(result['steps'][0]['expected'], '');
        expect(result['steps'][0]['data'], '');
      });

      test('normalizes steps with map entries', () {
        final result = normalizer.normalizeCase({
          'title': 'T',
          'steps': [
            {'action': 'Click', 'expectedResult': 'Opens', 'testData': 'x'},
          ],
        });
        expect(result['steps'].first['action'], 'Click');
        expect(result['steps'].first['expected'], 'Opens');
        expect(result['steps'].first['data'], 'x');
      });

      test('normalizes steps with step alias key', () {
        final result = normalizer.normalizeCase({
          'title': 'T',
          'steps': [
            {'step': 'Navigate', 'expected': 'Page loads'},
          ],
        });
        expect(result['steps'].first['action'], 'Navigate');
        expect(result['steps'].first['expected'], 'Page loads');
      });

      test('returns empty list for non-list steps', () {
        final result = normalizer.normalizeCase({
          'title': 'T',
          'steps': 'not a list',
        });
        expect(result['steps'], isEmpty);
      });
    });

    group('normalizeCases', () {
      test('normalizes a list of raw cases', () {
        final raw = [
          {'title': 'A', 'steps': [{'action': 'x'}]},
          {'title': 'B', 'steps': [{'action': 'y'}]},
        ];
        final result = normalizer.normalizeCases(raw);
        expect(result, hasLength(2));
        expect(result[0]['title'], 'A');
        expect(result[1]['title'], 'B');
      });

      test('filters non-Map entries', () {
        final raw = [
          {'title': 'A', 'steps': [{'action': 'x'}]},
          42,
          'string',
        ];
        final result = normalizer.normalizeCases(raw);
        expect(result, hasLength(1));
      });
    });
  });
}
