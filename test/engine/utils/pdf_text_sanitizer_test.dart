import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/utils/pdf_text_sanitizer.dart';

void main() {
  group('PdfTextSanitizer', () {
    test('sanitize returns empty string for empty input', () {
      expect(PdfTextSanitizer.sanitize(''), equals(''));
    });

    test('sanitize replaces bullet characters', () {
      expect(PdfTextSanitizer.sanitize('• bullet'), equals('| bullet'));
      expect(PdfTextSanitizer.sanitize('● black'), equals('| black'));
      expect(PdfTextSanitizer.sanitize('▪ small'), equals('- small'));
      expect(PdfTextSanitizer.sanitize('◦ white'), equals('- white'));
    });

    test('sanitize replaces dash and hyphen variants', () {
      expect(PdfTextSanitizer.sanitize('‑'), equals('-'));
      expect(PdfTextSanitizer.sanitize('–'), equals('-'));
      expect(PdfTextSanitizer.sanitize('—'), equals('-'));
      expect(PdfTextSanitizer.sanitize('−'), equals('-'));
    });

    test('sanitize replaces smart quotes', () {
      expect(PdfTextSanitizer.sanitize('"hello"'), equals('"hello"'));
      expect(PdfTextSanitizer.sanitize("'world'"), equals("'world'"));
    });

    test('sanitize replaces ellipsis and trademark', () {
      expect(PdfTextSanitizer.sanitize('…'), equals('...'));
      expect(PdfTextSanitizer.sanitize('™'), equals('TM'));
    });

    test('sanitize replaces arrow symbols', () {
      expect(PdfTextSanitizer.sanitize('→'), equals('->'));
      expect(PdfTextSanitizer.sanitize('←'), equals('<-'));
      expect(PdfTextSanitizer.sanitize('↑'), equals('^'));
      expect(PdfTextSanitizer.sanitize('↓'), equals('v'));
      expect(PdfTextSanitizer.sanitize('⇒'), equals('=>'));
      expect(PdfTextSanitizer.sanitize('⇐'), equals('<='));
    });

    test('sanitize replaces currency symbols', () {
      expect(PdfTextSanitizer.sanitize('€'), equals('EUR'));
      expect(PdfTextSanitizer.sanitize('₹'), equals('INR'));
    });

    test('sanitize leaves safe characters unchanged', () {
      expect(PdfTextSanitizer.sanitize('Hello World 123'), equals('Hello World 123'));
    });

    test('sanitize handles mixed content', () {
      const input = '• Item → "Note" — 100€';
      const expected = '| Item -> "Note" - 100EUR';
      expect(PdfTextSanitizer.sanitize(input), equals(expected));
    });
  });
}
