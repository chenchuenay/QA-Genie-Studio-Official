import 'dart:convert';
import 'package:crypto/crypto.dart';

class StableHash {
  static int forText(String text, int max) {
    if (max <= 1) return 0;
    final bytes = utf8.encode(text);
    final digest = sha1.convert(bytes);
    final hex = digest.toString().substring(0, 8);
    final val = int.parse(hex, radix: 16);
    return val.abs() % max;
  }
}
