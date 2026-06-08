import '../models/scenario.dart';

class DuplicationValidator {
  static bool isDuplicate(Scenario scenario, Set<Scenario> used) {
    return used.contains(scenario);
  }
}
