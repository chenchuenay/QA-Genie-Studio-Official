import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/engine/humanization/qa_heuristics_engine.dart';

void main() {
  group('QaHeuristicsEngine', () {
    group('isMeaningfulStep', () {
      test('returns false for weak actions', () {
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'open app', expected: 'system responds correctly')), isFalse);
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'click button', expected: 'system works')), isFalse);
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'perform action', expected: 'success')), isFalse);
      });

      test('returns false for edge case keywords', () {
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'check sql injections', expected: 'no errors occur')), isFalse);
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'verify xss', expected: 'everything is fine')), isFalse);
      });

      test('returns true for meaningful action and expected', () {
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'Enter valid email address', expected: 'Email field accepts the input and validates format')), isTrue);
      });

      test('returns false when action is too short', () {
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'go', expected: 'A long enough expected result here to pass')), isFalse);
      });

      test('returns false when expected is too short', () {
        expect(QaHeuristicsEngine.isMeaningfulStep(TestStep(action: 'A longer action that is meaningful', expected: 'short')), isFalse);
      });
    });

    group('semanticScore', () {
      TestCaseModel makeTC({String title = 'A meaningful test case title', String expectedResult = 'A sufficiently long expected result description', List<TestStep>? steps}) {
        return TestCaseModel(
          title: title,
          expectedResult: expectedResult,
          steps: steps ?? [
            TestStep(action: 'Enter valid email address', data: 'test@test.com', expected: 'The system validates and accepts the input'),
          ],
        );
      }

      test('returns 0 for minimal with weak words', () {
        final tc = TestCaseModel(title: 'short', expectedResult: 'works correctly', steps: [TestStep(action: 'go', data: '', expected: 'ok')]);
        expect(QaHeuristicsEngine.semanticScore(tc), equals(0));
      });

      test('awards points for meaningful content', () {
        final tc = makeTC();
        final score = QaHeuristicsEngine.semanticScore(tc);
        expect(score, greaterThan(0));
      });

      test('awards points for long title', () {
        final tc = makeTC(title: 'This is a long and meaningful test case title that exceeds fifteen characters');
        expect(QaHeuristicsEngine.semanticScore(tc), greaterThanOrEqualTo(1));
      });

      test('returns positive score when no weak words present', () {
        final tc = makeTC();
        final score = QaHeuristicsEngine.semanticScore(tc);
        expect(score, greaterThan(0));
      });
    });

    group('loginRisks', () {
      test('contains expected risk items', () {
        expect(QaHeuristicsEngine.loginRisks, contains('Session fixation'));
        expect(QaHeuristicsEngine.loginRisks, contains('Credential stuffing'));
      });
    });

    group('inferDomain', () {
      test('returns auth for login keywords', () {
        expect(QaHeuristicsEngine.inferDomain('Auth', 'login', 'general'), equals('auth'));
      });

      test('returns payment for checkout keywords', () {
        expect(QaHeuristicsEngine.inferDomain('Store', 'checkout', 'general'), equals('payment'));
      });

      test('returns file for upload keywords', () {
        expect(QaHeuristicsEngine.inferDomain('Docs', 'upload file', 'general'), equals('file'));
      });

      test('returns general for no match', () {
        expect(QaHeuristicsEngine.inferDomain('Random', 'Unknown', 'general'), equals('general'));
      });

      test('prefers auth over other domains when multiple match', () {
        expect(QaHeuristicsEngine.inferDomain('Auth', 'checkout payment login', 'general'), equals('auth'));
      });
    });

    group('priorityFor', () {
      test('returns High for payment related features', () {
        expect(QaHeuristicsEngine.priorityFor(category: 'positive', module: 'Store', feature: 'checkout', title: 'Process payment', platform: 'WEB'), equals('High'));
      });

      test('returns High for data loss concerns', () {
        expect(QaHeuristicsEngine.priorityFor(category: 'security', module: 'Admin', feature: 'Settings', title: 'delete account', platform: 'WEB'), equals('High'));
      });

      test('returns Low for usability', () {
        expect(QaHeuristicsEngine.priorityFor(category: 'usability', module: 'UI', feature: 'Theme', title: 'Change color', platform: 'Mobile'), equals('Low'));
      });

      test('returns Medium otherwise', () {
        expect(QaHeuristicsEngine.priorityFor(category: 'positive', module: 'Profile', feature: 'View', title: 'Display user info', platform: 'WEB'), equals('Medium'));
      });
    });

    group('inferCategory', () {
      test('returns security for security keywords', () {
        expect(QaHeuristicsEngine.inferCategory('functional', 'XSS attack test'), equals('security'));
      });

      test('returns boundary for limit keywords', () {
        expect(QaHeuristicsEngine.inferCategory('functional', 'test maximum input length'), equals('boundary'));
      });

      test('returns validation for format keywords', () {
        expect(QaHeuristicsEngine.inferCategory('functional', 'invalid email format'), equals('validation'));
      });

      test('returns positive for success keywords', () {
        expect(QaHeuristicsEngine.inferCategory('functional', 'successful login'), equals('positive'));
      });

      test('returns original category if no keywords match', () {
        expect(QaHeuristicsEngine.inferCategory('custom', 'something else'), equals('custom'));
      });
    });

    group('scenarioMatchesContext', () {
      test('returns false for login context with checkout scenario', () {
        expect(QaHeuristicsEngine.scenarioMatchesContext('Checkout process', 'Login', 'sign in', 'auth'), isFalse);
      });

      test('returns true for matching auth scenario', () {
        expect(QaHeuristicsEngine.scenarioMatchesContext('Login with valid credentials', 'Auth', 'login', 'auth'), isTrue);
      });

      test('returns true for general domain', () {
        expect(QaHeuristicsEngine.scenarioMatchesContext('Any scenario', 'General', 'Feature', 'general'), isTrue);
      });
    });

    group('expectedResult', () {
      test('returns API-specific expected for API platform', () {
        final result = QaHeuristicsEngine.expectedResult(platform: 'API', category: 'security', module: 'Auth', feature: 'Login', title: 'Test XSS');
        expect(result, contains('unauthorized'));
      });

      test('returns mobile-specific expected for Mobile platform', () {
        final result = QaHeuristicsEngine.expectedResult(platform: 'Mobile', category: 'positive', module: 'Store', feature: 'Checkout', title: 'Complete order');
        expect(result, contains('screen'));
      });

      test('returns web-specific expected for other platforms', () {
        final result = QaHeuristicsEngine.expectedResult(platform: 'WEB', category: 'negative', module: 'Auth', feature: 'Login', title: 'Invalid email');
        expect(result, contains('form submission'));
      });
    });

    group('hasWeakExpectedResult', () {
      test('returns true for short text', () {
        expect(QaHeuristicsEngine.hasWeakExpectedResult('Short'), isTrue);
      });

      test('returns true for generic phrases', () {
        expect(QaHeuristicsEngine.hasWeakExpectedResult('The system works correctly and returns appropriate response'), isTrue);
      });

      test('returns false for strong expected result', () {
        expect(QaHeuristicsEngine.hasWeakExpectedResult('The application validates the email format and displays an inline error message for invalid inputs with proper field highlighting'), isFalse);
      });
    });
  });
}
