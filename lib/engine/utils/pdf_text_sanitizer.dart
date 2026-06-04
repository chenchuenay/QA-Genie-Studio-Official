/// Minimal PDF text sanitizer – replaces only characters that are known to
/// render as missing glyph boxes in the PDF library.
/// Applied ONLY at the PDF rendering layer; does not modify stored data.
class PdfTextSanitizer {
  static String sanitize(String input) {
    if (input.isEmpty) return input;
    return input
        .replaceAll('•', '|') // bullet
        .replaceAll('●', '|') // black bullet
        .replaceAll('▪', '-') // small square bullet
        .replaceAll('◦', '-') // white bullet
        .replaceAll('‑', '-') // non-breaking hyphen
        .replaceAll('–', '-') // en dash
        .replaceAll('—', '-') // em dash
        .replaceAll('−', '-') // minus sign
        .replaceAll('“', '"') // left smart double quote
        .replaceAll('”', '"') // right smart double quote
        .replaceAll('‘', "'") // left smart single quote
        .replaceAll('’', "'") // right smart single quote
        .replaceAll('…', '...') // ellipsis
        .replaceAll('™', 'TM') // trademark
        // Arrows
        .replaceAll('→', '->')
        .replaceAll('←', '<-')
        .replaceAll('↑', '^')
        .replaceAll('↓', 'v')
        .replaceAll('⇒', '=>')
        .replaceAll('⇐', '<=')
        // Currency symbols
        .replaceAll('€', 'EUR')
        .replaceAll('₹', 'INR');
    // Note: ©, ®, $, £, ¥ are left unchanged – they render correctly.
  }
}
