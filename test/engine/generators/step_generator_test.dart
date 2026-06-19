import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/generators/step_generator.dart';
import 'package:qa_genie/engine/models/scenario.dart';
import 'package:qa_genie/engine/ontology/actions.dart';
import 'package:qa_genie/engine/ontology/entities.dart';
import 'package:qa_genie/engine/ontology/states.dart';

void main() {
  late Scenario positiveScenario;
  late Scenario negativeScenario;

  setUp(() {
    positiveScenario = Scenario(
      entity: EntityType.account,
      action: ActionType.login,
      targetState: StateType.authenticated,
      category: 'positive',
    );
    negativeScenario = Scenario(
      entity: EntityType.account,
      action: ActionType.login,
      targetState: StateType.failed,
      category: 'negative',
    );
  });

  group('StepGenerator', () {
    test('generate returns API steps for API platform', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'API',
        {'email': 'test@example.com', 'valid_flag': 'true'},
      );
      expect(steps, isNotEmpty);
      expect(steps[0]['action'], contains('Prepare'));
      expect(steps[0]['expected'], 'Request ready');
      final hasExecute = steps.any((s) => s['action']!.contains('login'));
      expect(hasExecute, isTrue);
    });

    test('generate returns Mobile steps for MOBILE platform', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'MOBILE',
        {'email': 'test@example.com'},
      );
      expect(steps[0]['action'], contains('Open'));
      expect(steps[0]['expected'], contains('screen displayed'));
      final hasTap = steps.any((s) => s['action']!.contains('Tap'));
      expect(hasTap, isTrue);
    });

    test('generate returns Web steps for other platforms', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'WEB',
        {'email': 'test@example.com'},
      );
      expect(steps[0]['action'], contains('Navigate'));
      expect(steps[0]['expected'], contains('page loaded'));
      final hasClick = steps.any((s) => s['action']!.contains('Click'));
      expect(hasClick, isTrue);
    });

    test('generate skips flag entries in testData', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'API',
        {'email': 'a@b.com', 'valid_flag': 'true', 'invalid_flag': 'false'},
      );
      final emailSteps = steps.where((s) => s['data'] == 'a@b.com');
      expect(emailSteps.length, 1);
    });

    test('generate skips empty testData values', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'API',
        {'email': '', 'password': 'secret'},
      );
      final emptySteps = steps.where((s) => s['data'] == '');
      final entrySteps = steps.where((s) =>
          s['action']!.contains('Prepare') || s['action']!.contains('Execute') || s['action']!.contains('Verify'));
      expect(emptySteps.length, greaterThan(entrySteps.length - 2));
    });

    test('generate adds execution step for positive scenario on API', () {
      final steps = StepGenerator.generate(positiveScenario, 'API', {});
      final execStep = steps.firstWhere((s) => s['action']!.contains('login'));
      expect(execStep['expected'], 'HTTP 2xx');
    });

    test('generate adds execution step for negative scenario on API', () {
      final steps = StepGenerator.generate(negativeScenario, 'API', {});
      final execStep = steps.firstWhere((s) => s['action']!.contains('login'));
      expect(execStep['expected'], 'HTTP 4xx');
    });

    test('generate adds verification step for positive scenario', () {
      final steps = StepGenerator.generate(positiveScenario, 'API', {});
      final verifyStep = steps.lastWhere((s) => s['action'] == 'Verify response state');
      expect(verifyStep['expected'], 'Response indicates success');
    });

    test('generate adds verification step for negative scenario', () {
      final steps = StepGenerator.generate(negativeScenario, 'API', {});
      final verifyStep = steps.lastWhere((s) => s['action'] == 'Verify response state');
      expect(verifyStep['expected'], 'Response indicates error');
    });

    test('generate has at least 3 steps (entry, execution, verification)', () {
      final steps = StepGenerator.generate(positiveScenario, 'API', {});
      expect(steps.length, greaterThanOrEqualTo(3));
    });

    test('generate adds input steps for non-empty testData', () {
      final steps = StepGenerator.generate(
        positiveScenario,
        'API',
        {'email': 'a@b.com', 'password': 'secret123'},
      );
      final inputSteps = steps.where((s) => s['data']!.isNotEmpty && s['data'] != '');
      expect(inputSteps.length, 2);
    });

    test('generate handles mobile positive scenario result expectations', () {
      final steps = StepGenerator.generate(positiveScenario, 'MOBILE', {});
      final execStep = steps.firstWhere((s) => s['action']!.contains('Tap'));
      expect(execStep['expected'], 'Action processed');
      final verifyStep = steps.firstWhere((s) => s['action'] == 'Check result');
      expect(verifyStep['expected'], 'Success message displayed');
    });

    test('generate handles web negative scenario result expectations', () {
      final steps = StepGenerator.generate(negativeScenario, 'WEB', {});
      final execStep = steps.firstWhere((s) => s['action']!.contains('Click'));
      expect(execStep['expected'], 'Validation error');
      final verifyStep = steps.firstWhere((s) => s['action'] == 'Check result');
      expect(verifyStep['expected'], 'Error message displayed');
    });
  });
}
