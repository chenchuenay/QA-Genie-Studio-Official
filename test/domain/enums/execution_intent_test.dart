import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/domain/enums/execution_intent.dart';

void main() {
  group('ExecutionIntent', () {
    test('all values are present', () {
      expect(ExecutionIntent.values.length, 12);
      expect(ExecutionIntent.values, contains(ExecutionIntent.persistenceValidation));
      expect(ExecutionIntent.values, contains(ExecutionIntent.interruptionRecovery));
      expect(ExecutionIntent.values, contains(ExecutionIntent.duplicateProtection));
      expect(ExecutionIntent.values, contains(ExecutionIntent.stateIntegrity));
      expect(ExecutionIntent.values, contains(ExecutionIntent.sessionIsolation));
      expect(ExecutionIntent.values, contains(ExecutionIntent.retrySafety));
      expect(ExecutionIntent.values, contains(ExecutionIntent.dataRetention));
      expect(ExecutionIntent.values, contains(ExecutionIntent.uiConsistency));
      expect(ExecutionIntent.values, contains(ExecutionIntent.workflowRecovery));
      expect(ExecutionIntent.values, contains(ExecutionIntent.navigationIntegrity));
      expect(ExecutionIntent.values, contains(ExecutionIntent.positive));
      expect(ExecutionIntent.values, contains(ExecutionIntent.usability));
    });
  });
}
