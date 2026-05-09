import 'test_step.dart';
class TestCase {
  final String id, title, module, feature, platform, priority, type;
  final List<String> preconditions;
  final List<TestStep> steps;
  final String expectedResult, actualResult, status;
  const TestCase({required this.id, required this.title, required this.module, required this.feature, required this.platform, required this.priority, required this.type, required this.preconditions, required this.steps, required this.expectedResult, this.actualResult = '', this.status = 'Not Executed'});
}
