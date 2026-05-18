
class RepairEvent {
  final String testCaseId;
  final String changedField;
  final String before;
  final String after;
  final String reason;

  RepairEvent({
    required this.testCaseId,
    required this.changedField,
    required this.before,
    required this.after,
    required this.reason,
  });

  @override
  String toString() =>
      'ID: $testCaseId | Field: $changedField | Reason: $reason\n  Before: $before\n  After: $after';
}
