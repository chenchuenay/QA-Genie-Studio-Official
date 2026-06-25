import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/data/models/test_case_model.dart';
import 'package:qa_genie/domain/enums/case_source.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';
import 'package:qa_genie/domain/enums/test_case_origin.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

void main() {
  group('TestCaseModel', () {
    final step = TestStep(action: 'Enter username', data: 'admin', expected: 'Field is populated');
    final base = TestCaseModel(
      source: CaseSource.ai,
      dbId: 1,
      id: 'TC-001',
      title: 'Verify login functionality',
      module: 'Auth',
      feature: 'Login',
      platform: 'Web',
      priority: 'High',
      type: 'Functional',
      preconditions: ['User is on login page'],
      steps: [step],
      expectedResult: 'User is logged in',
      actualResult: '',
      status: 'Not Executed',
      intent: ExecutionIntent.stateIntegrity,
    );

    test('constructor sets fields with defaults', () {
      expect(base.source, CaseSource.ai);
      expect(base.dbId, 1);
      expect(base.id, 'TC-001');
      expect(base.title, 'Verify login functionality');
      expect(base.module, 'Auth');
      expect(base.feature, 'Login');
      expect(base.platform, 'Web');
      expect(base.priority, 'High');
      expect(base.type, 'Functional');
      expect(base.preconditions, ['User is on login page']);
      expect(base.steps, [step]);
      expect(base.expectedResult, 'User is logged in');
      expect(base.actualResult, '');
      expect(base.status, 'Not Executed');
      expect(base.intent, ExecutionIntent.stateIntegrity);
      expect(base.forensicOrigin, TestCaseOrigin.ai);
      expect(base.repairOperations, []);
      expect(base.realismOperations, []);
    });

    test('isValid returns true for valid test case', () {
      expect(TestCaseModel.isValid(base), true);
    });

    test('isValid returns false for short title', () {
      final invalid = base.copyWith(title: 'ABC');
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('isValid returns false for empty expectedResult', () {
      final invalid = base.copyWith(expectedResult: '');
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('isValid returns false for invalid priority', () {
      final invalid = base.copyWith(priority: 'Urgent');
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('isValid returns false for empty steps', () {
      final invalid = base.copyWith(steps: []);
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('isValid returns false for step with short action', () {
      final invalid = base.copyWith(
        steps: [TestStep(action: 'AB', data: '', expected: 'OK')],
      );
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('isValid returns false for banned data phrase in step', () {
      final invalid = base.copyWith(
        steps: [TestStep(action: 'Enter data', data: 'test data', expected: 'OK')],
      );
      expect(TestCaseModel.isValid(invalid), false);
    });

    test('toJson serializes correctly', () {
      final json = base.toJson();
      expect(json['id'], 'TC-001');
      expect(json['title'], 'Verify login functionality');
      expect(json['module'], 'Auth');
      expect(json['feature'], 'Login');
      expect(json['platform'], 'Web');
      expect(json['priority'], 'High');
      expect(json['type'], 'Functional');
      expect(json['preconditions'], ['User is on login page']);
      expect(json['steps'], isA<List>());
      expect(json['expectedResult'], 'User is logged in');
      expect(json['actualResult'], '');
      expect(json['status'], 'Not Executed');
      expect(json['source'], 'ai');
      expect(json['dbId'], 1);
      expect(json['intent'], 'stateIntegrity');
    });

    test('fromJson deserializes correctly', () {
      final json = base.toJson();
      final reconstructed = TestCaseModel.fromJson(json);
      expect(reconstructed.id, base.id);
      expect(reconstructed.title, base.title);
      expect(reconstructed.priority, base.priority);
      expect(reconstructed.type, base.type);
      expect(reconstructed.source, base.source);
      expect(reconstructed.steps.length, base.steps.length);
      expect(reconstructed.steps.first.action, base.steps.first.action);
    });

    test('fromJson handles missing fields', () {
      final reconstructed = TestCaseModel.fromJson({});
      expect(reconstructed.id, '');
      expect(reconstructed.title, '');
      expect(reconstructed.priority, 'Medium');
      expect(reconstructed.type, 'Functional');
      expect(reconstructed.source, CaseSource.ai);
      expect(reconstructed.preconditions, isNotEmpty);
      expect(reconstructed.steps.length, 3);
    });

    test('fromJson handles critical priority normalization', () {
      final json = base.toJson();
      json['priority'] = 'critical';
      final reconstructed = TestCaseModel.fromJson(json);
      expect(reconstructed.priority, 'High');
    });

    test('fromJson handles low priority normalization', () {
      final json = base.toJson();
      json['priority'] = 'low';
      final reconstructed = TestCaseModel.fromJson(json);
      expect(reconstructed.priority, 'Low');
    });

    test('fromJson handles intent parsing', () {
      final json = base.toJson();
      json['intent'] = 'duplicateProtection';
      final reconstructed = TestCaseModel.fromJson(json);
      expect(reconstructed.intent, ExecutionIntent.duplicateProtection);
    });

    test('fromJson handles invalid intent', () {
      final json = base.toJson();
      json['intent'] = 'invalidIntentName';
      final reconstructed = TestCaseModel.fromJson(json);
      expect(reconstructed.intent, isNull);
    });

    test('stepsDisplayString formats correctly', () {
      final model = TestCaseModel(
        steps: [
          TestStep(action: 'Step one', data: '', expected: ''),
          TestStep(action: 'Step two', data: '', expected: ''),
        ],
      );
      expect(model.stepsDisplayString, '1. Step one\n2. Step two');
    });

    test('copyWith overrides fields', () {
      final copy = base.copyWith(title: 'New title', priority: 'Low');
      expect(copy.title, 'New title');
      expect(copy.priority, 'Low');
      expect(copy.dbId, 1);
    });

    test('copyWith keeps steps as new instances', () {
      final copy = base.copyWith();
      expect(copy.steps, isNot(same(base.steps)));
    });

    test('copy creates independent instance', () {
      final copy = base.copy();
      expect(copy.title, base.title);
      expect(copy.source, base.source);
      expect(copy.preconditions, isNot(same(base.preconditions)));
      expect(copy.steps, isNot(same(base.steps)));
    });
  });
}
