import '../model/domain_ontology.dart';
import 'domains/identity_domain.dart';
import 'domains/commerce_domain.dart';
import 'domains/banking_domain.dart';
import 'domains/medical_domain.dart';
import 'domains/scheduling_domain.dart';
import 'domains/integration_domain.dart';
import 'domains/ai_ml_domain.dart';
import 'domains/social_domain.dart';
import 'domains/tech_domain.dart';
import 'domains/robotics_domain.dart';

class DomainIndex {
  static final Map<String, DomainOntology> _all = {
    'identity': identityDomain,
    'commerce': commerceDomain,
    'banking': bankingDomain,
    'medical': medicalDomain,
    'scheduling': schedulingDomain,
    'integration': integrationDomain,
    'ai_ml': aiMlDomain,
    'social': socialDomain,
    'tech': techDomain,
    'robotics': roboticsDomain,
  };

  static final List<DomainOntology> allDomains = _all.values.toList();

  static DomainOntology? byId(String id) => _all[id];

  static DomainOntology? detect(String module, String feature) {
    final combined = '$module $feature'.toLowerCase();
    DomainOntology? bestMatch;
    int bestScore = 0;

    for (final domain in _all.values) {
      int score = 0;
      for (final synonym in domain.synonyms) {
        if (combined.contains(synonym.toLowerCase())) {
          score += synonym.length;
        }
      }
      if (score > bestScore) {
        bestScore = score;
        bestMatch = domain;
      }
    }

    return bestMatch;
  }

  static void register(DomainOntology domain) {
    _all[domain.id] = domain;
  }
}
