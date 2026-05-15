import 'dart:convert';
import 'package:crypto/crypto.dart';

class StableHash {
  const StableHash._();

  static int forText(String text, int max) {
    if (max <= 1) return 0;

    final normalized = text.trim().toLowerCase();

    if (normalized.isEmpty) {
      return 0;
    }

    final bytes = utf8.encode(normalized);

    final digest = sha1.convert(bytes).bytes;

    int hash = 0;

    for (int i = 0; i < 4; i++) {
      hash = (hash << 8) | digest[i];
    }

    return hash % max;
  }
}
