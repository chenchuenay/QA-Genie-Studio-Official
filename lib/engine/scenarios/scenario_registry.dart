import '../models/scenario.dart';
import '../models/domain_context.dart';
import 'scenario_factory.dart'; // ADD THIS IMPORT

class ScenarioRegistry {
  static final Map<String, List<Scenario>> _cache = {};

  static List<Scenario> getForDomain(DomainContext domain) {
    final key = domain.id;
    if (_cache.containsKey(key)) return _cache[key]!;
    final scenarios = ScenarioFactory.fromDomain(domain);
    _cache[key] = scenarios;
    return scenarios;
  }
}
