import '../ontology/constraints.dart';

class ConstraintParser {
  final String rawConstraints;

  ConstraintParser(this.rawConstraints);

  ConstraintParserResult parse() {
    final intent = ConstraintUtils.detectIntent(rawConstraints);
    final keywords = ConstraintUtils.extractKeywords(rawConstraints);
    return ConstraintParserResult(intent: intent, keywords: keywords);
  }
}
