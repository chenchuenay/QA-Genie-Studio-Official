import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/entities/test_step.dart';

void main() {
  group('TestStep', () {
    test('constructor sets fields correctly', () {
      final step = TestStep(action: 'Click login', data: 'user@test.com', expected: 'Dashboard loads');
      expect(step.action, 'Click login');
      expect(step.data, 'user@test.com');
      expect(step.expected, 'Dashboard loads');
    });

    test('constructor uses empty defaults', () {
      final step = TestStep(action: 'Tap');
      expect(step.action, 'Tap');
      expect(step.data, '');
      expect(step.expected, '');
    });

    test('fromJson parses correctly', () {
      final step = TestStep.fromJson({'action': 'Enter email', 'data': 'admin@demo.com', 'expected': 'Field accepts input'});
      expect(step.action, 'Enter email');
      expect(step.data, 'admin@demo.com');
      expect(step.expected, 'Field accepts input');
    });

    test('fromJson uses defaults for null values', () {
      final step = TestStep.fromJson({});
      expect(step.action, '');
      expect(step.data, '');
      expect(step.expected, '');
    });

    test('toJson produces correct map', () {
      final step = TestStep(action: 'Submit', data: 'form data', expected: '200 OK');
      expect(step.toJson(), {'action': 'Submit', 'data': 'form data', 'expected': '200 OK'});
    });

    test('copyWith preserves unchanged fields', () {
      final step = TestStep(action: 'A', data: 'B', expected: 'C');
      final copy = step.copyWith(action: 'X');
      expect(copy.action, 'X');
      expect(copy.data, 'B');
      expect(copy.expected, 'C');
    });

    test('copyWith overrides all fields', () {
      final step = TestStep(action: 'A', data: 'B', expected: 'C');
      final copy = step.copyWith(action: '1', data: '2', expected: '3');
      expect(copy.action, '1');
      expect(copy.data, '2');
      expect(copy.expected, '3');
    });
  });
}
