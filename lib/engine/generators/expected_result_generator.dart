import '../models/scenario.dart';
import '../ontology/states.dart';

class ExpectedResultGenerator {
  static String generate(Scenario scenario) {
    final outcome = _observableOutcome(scenario.targetState);
    if (scenario.isPositive) {
      return outcome.positive;
    } else {
      return outcome.negative;
    }
  }

  static _Outcome _observableOutcome(StateType state) {
    switch (state) {
      case StateType.authenticated:
        return _Outcome(
          'Dashboard is displayed',
          'Error message: Authentication failed',
        );
      case StateType.authorized:
        return _Outcome(
          'Protected content is visible',
          'Access denied message appears',
        );
      case StateType.active:
        return _Outcome('Operation completed', 'Operation failed, error shown');
      case StateType.completed:
        return _Outcome('Confirmation message appears', 'Transaction failed');
      case StateType.created:
        return _Outcome('New item is created', 'Creation failed');
      case StateType.updated:
        return _Outcome('Changes are saved', 'Update failed');
      case StateType.deleted:
        return _Outcome('Item is removed', 'Deletion failed');
      case StateType.scheduled:
        return _Outcome('Appointment confirmed', 'Scheduling failed');
      case StateType.redirected:
        return _Outcome('Page redirects', 'Redirect failed');
      default:
        return _Outcome('Success', 'Error');
    }
  }
}

class _Outcome {
  final String positive;
  final String negative;
  _Outcome(this.positive, this.negative);
}
