class ContentFilter {
  ContentFilter._();

  static final RegExp _htmlTags = RegExp(
    r'<[^>]*>|<\/[^>]*>|<\s*script|<\s*iframe',
    caseSensitive: false,
  );

  static final RegExp _controlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

  static final List<RegExp> _profanityPatterns = [
    RegExp(r'\banal\b', caseSensitive: false),
    RegExp(r'\bass\b', caseSensitive: false),
    RegExp(r'\basshole(s)?\b', caseSensitive: false),
    RegExp(r'\bballs?\b', caseSensitive: false),
    RegExp(r'\bbastard(s|ly|ize)?\b', caseSensitive: false),
    RegExp(r'\bbeastiality\b', caseSensitive: false),
    RegExp(r'\bbimbo(s)?\b', caseSensitive: false),
    RegExp(r'\bbitch(es|ing|ed|y|ier|iest)?\b', caseSensitive: false),
    RegExp(r'\bboner(s)?\b', caseSensitive: false),
    RegExp(r'\bboob(s|y)?\b', caseSensitive: false),
    RegExp(r'\bbullshit\b', caseSensitive: false),
    RegExp(r'\bchink(s)?\b', caseSensitive: false),
    RegExp(r'\bclit(s|oris)?\b', caseSensitive: false),
    RegExp(r'\bcock(s|head|heads|sucker|suckers)?\b', caseSensitive: false),
    RegExp(r'\bcum(s|ming|med|shot|shots)?\b', caseSensitive: false),
    RegExp(r'\bcunt(s)?\b', caseSensitive: false),
    RegExp(r'\bdick(s|head|heads|wad|weed|bag|bags)?\b', caseSensitive: false),
    RegExp(r'\bdildo(s)?\b', caseSensitive: false),
    RegExp(r'\bdouche(bag|bags|s|y)?\b', caseSensitive: false),
    RegExp(r'\bdyke(s)?\b', caseSensitive: false),
    RegExp(r'\bejaculat(e|es|ed|ing|ion)\b', caseSensitive: false),
    RegExp(r'\bfag(s|got|gots|gotry|g)?\b', caseSensitive: false),
    RegExp(r'\bfaggot(s|ry)?\b', caseSensitive: false),
    RegExp(r'\bfecal\b', caseSensitive: false),
    RegExp(r'\bfelch(ing|ed|es)?\b', caseSensitive: false),
    RegExp(r'\bfellat(e|io|ing|ed)?\b', caseSensitive: false),
    RegExp(r'\bfuck(ing|ed|er|ers|s|tard|wit)?\b', caseSensitive: false),
    RegExp(r'\bgangbang(s|ing|ed|er)?\b', caseSensitive: false),
    RegExp(r'\bgoddamn\b', caseSensitive: false),
    RegExp(r'\bgook(s)?\b', caseSensitive: false),
    RegExp(r'\bgrop(e|ing|ed|es)\b', caseSensitive: false),
    RegExp(r'\bjackass(es)?\b', caseSensitive: false),
    RegExp(r'\bjerk(s|ing|ed|off)?\b', caseSensitive: false),
    RegExp(r'\bjizz\b', caseSensitive: false),
    RegExp(r'\bkike(s)?\b', caseSensitive: false),
    RegExp(r'\bknob(s|ber)?\b', caseSensitive: false),
    RegExp(r'\blabia(l|e)?\b', caseSensitive: false),
    RegExp(r'\bmasturbat(e|es|ing|ion|ory)\b', caseSensitive: false),
    RegExp(r'\bmilf(s)?\b', caseSensitive: false),
    RegExp(r'\bmolest(er|ers|ing|ed|ation)?\b', caseSensitive: false),
    RegExp(r'\bmoron(s)?\b', caseSensitive: false),
    RegExp(r'\bmotherfuck(er|ers|ing|ed)\b', caseSensitive: false),
    RegExp(r'\bmotherfucker(s)?\b', caseSensitive: false),
    RegExp(r'\bnazi(s)?\b', caseSensitive: false),
    RegExp(r'\bnigg(a|er|as|az|let|lets)?\b', caseSensitive: false),
    RegExp(r'\bnud(e|ity|es|ist)?\b', caseSensitive: false),
    RegExp(r'\borgasm(s|ic)?\b', caseSensitive: false),
    RegExp(r'\bpenis(es)?\b', caseSensitive: false),
    RegExp(r'\bpimp(s|ing|ed)?\b', caseSensitive: false),
    RegExp(r'\bpiss(ing|ed|es|er|ers|off)?\b', caseSensitive: false),
    RegExp(r'\bporn(o|s|y|ography)?\b', caseSensitive: false),
    RegExp(r'\bprecum\b', caseSensitive: false),
    RegExp(r'\bprick(s)?\b', caseSensitive: false),
    RegExp(r'\bprostitut(e|es|ing|ion)?\b', caseSensitive: false),
    RegExp(r'\bpussy|pussies\b', caseSensitive: false),
    RegExp(r'\bqueer(s)?\b', caseSensitive: false),
    RegExp(r'\brap(e|ing|es|ed)\b', caseSensitive: false),
    RegExp(r'\brapist(s)?\b', caseSensitive: false),
    RegExp(r'\brectum|rectal\b', caseSensitive: false),
    RegExp(r'\bretard(ed|s|ation)?\b', caseSensitive: false),
    RegExp(r'\bschlong(s)?\b', caseSensitive: false),
    RegExp(r'\bscrotum|scrotal\b', caseSensitive: false),
    RegExp(r'\bsemen\b', caseSensitive: false),
    RegExp(r'\bshit(ting|ted|s|e|ty|head|heads|bag|bags|hole|holes)?\b',
        caseSensitive: false),
    RegExp(r'\bslut(s|ty|tier|tiest|ting)?\b', caseSensitive: false),
    RegExp(r'\bsodom(y|ize|izing|ized|ite|ites)?\b', caseSensitive: false),
    RegExp(r'\bspic(s)?\b', caseSensitive: false),
    RegExp(r'\bspunk\b', caseSensitive: false),
    RegExp(r'\bstripper(s)?\b', caseSensitive: false),
    RegExp(r'\btit(s|ty|ties)?\b', caseSensitive: false),
    RegExp(r'\btosser(s)?\b', caseSensitive: false),
    RegExp(r'\btramp(s)?\b', caseSensitive: false),
    RegExp(r'\btranny|trannies\b', caseSensitive: false),
    RegExp(r'\btwat(s)?\b', caseSensitive: false),
    RegExp(r'\bvagina(l|s)?\b', caseSensitive: false),
    RegExp(r'\bvibrator(s)?\b', caseSensitive: false),
    RegExp(r'\bvulva(l)?\b', caseSensitive: false),
    RegExp(r'\bwank(er|ers|ing|ed)?\b', caseSensitive: false),
    RegExp(r'\bwhor(e|ing|es|ed|ish|ehouse)\b', caseSensitive: false),
  ];

  static ContentFilterResult check(String input) {
    final findings = <String>[];

    if (input.trim().isEmpty) {
      return ContentFilterResult(
        isClean: true,
        sanitized: input,
        findings: findings,
      );
    }

    for (final pattern in _profanityPatterns) {
      if (pattern.hasMatch(input)) {
        findings.add('profanity');
        break;
      }
    }

    if (_htmlTags.hasMatch(input)) {
      findings.add('html_tags');
    }

    return ContentFilterResult(
      isClean: findings.isEmpty,
      sanitized: input,
      findings: findings,
    );
  }

  static String sanitizeField(String input) {
    String result = input;

    result = result.replaceAll(_htmlTags, ' ');
    result = result.replaceAll(_controlChars, ' ');

    for (final pattern in _profanityPatterns) {
      result = result.replaceAllMapped(
        pattern,
        (m) => '*' * m.group(0)!.length,
      );
    }

    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

class ContentFilterResult {
  final bool isClean;
  final String sanitized;
  final List<String> findings;

  const ContentFilterResult({
    required this.isClean,
    required this.sanitized,
    required this.findings,
  });
}
