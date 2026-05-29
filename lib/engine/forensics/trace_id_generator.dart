import 'dart:math';

class TraceIdGenerator {
  static final Random _random = Random.secure();

  static String generate({String tier = 'CORE', String platform = 'GEN'}) {
    final ts = DateTime.now().millisecondsSinceEpoch;

    final randomHex = List.generate(
      6,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();

    final normalizedTier = tier.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    final normalizedPlatform = platform.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );

    return 'TRACE-$normalizedTier-$normalizedPlatform-$ts-$randomHex';
  }

  static String short() {
    final randomHex = List.generate(
      8,
      (_) => _random.nextInt(16).toRadixString(16),
    ).join().toUpperCase();

    return 'QG-$randomHex';
  }
}
