import 'dart:math';
import 'package:qa_genie/core/utils/stable_hash.dart';
import 'package:qa_genie/domain/enums/generation_mode.dart';
import 'package:qa_genie/engine/knowledge/intent_registry.dart';

class ScenarioPlanner {
  final String module;
  final String feature;
  final String platform;
  final GenerationMode mode;
  final int count;
  final String domain;
  final String constraints;

  final Random _random;

  ScenarioPlanner({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    this.domain = 'general',
    this.constraints = '',
    int? seed,
  }) : _random = Random(
         seed ?? _generateSeed(module, feature, platform, domain, constraints),
       );

  static int _generateSeed(
    String module,
    String feature,
    String platform,
    String domain,
    String constraints,
  ) {
    return StableHash.forText(
      '$module|$feature|$platform|$domain|$constraints',
      99999999,
    );
  }

  Random get random => _random;
  String get stableSeed => '$module|$feature|$platform|$domain|$constraints';

  bool get _securityFocused {
    final c = constraints.toLowerCase();
    return c.contains('security') ||
        c.contains('sql') ||
        c.contains('xss') ||
        c.contains('token') ||
        c.contains('auth') ||
        c.contains('unauthorized') ||
        c.contains('csrf');
  }

  bool get _negativeFocused {
    final c = constraints.toLowerCase();
    return c.contains('negative') ||
        c.contains('invalid') ||
        c.contains('boundary') ||
        c.contains('edge') ||
        c.contains('validation');
  }

  bool get _sessionFocused {
    final c = constraints.toLowerCase();
    return c.contains('session') ||
        c.contains('timeout') ||
        c.contains('expiry') ||
        c.contains('logout');
  }

  String get _businessArea {
    final f = feature.toLowerCase();
    final d = domain.toLowerCase();
    const authAliases = ['login', 'signin', 'sign in', 'authentication', 'access', 'member entry', 'auth', 'signup', 'registration', 'register', 'password', 'forgot password'];
    for (final a in authAliases) if (f.contains(a)) return 'authentication';
    if (d == 'ecommerce' ||
        f.contains('checkout') || f.contains('cart') || f.contains('order') ||
        f.contains('payment') || f.contains('refund') || f.contains('coupon') ||
        f.contains('wishlist') || f.contains('purchase')) return 'ecommerce';
    if (d == 'banking' ||
        f.contains('transfer') || f.contains('beneficiary') || f.contains('balance') ||
        f.contains('statement') || f.contains('loan') || f.contains('deposit') ||
        f.contains('otp') || f.contains('transaction')) return 'banking';
    if (d == 'healthcare' ||
        f.contains('appointment') || f.contains('prescription') || f.contains('patient') ||
        f.contains('doctor') || f.contains('medical') || f.contains('clinic')) return 'healthcare';
    return 'general';
  }

  List<Map<String, dynamic>> generateSkeletons() {
    final skeletons = <Map<String, dynamic>>[];
    final usedIntents = <String>{};

    // Determine category distribution (80/20 base)
    int happyCount, otherCount;
    List<String> otherCategories;

    if (_securityFocused) {
      happyCount = (count * 0.2).floor();
      final securityCount = (count * 0.6).floor();
      final negativeCount = (count * 0.2).floor();
      otherCount = securityCount + negativeCount;
      otherCategories = [];
      for (int i = 0; i < securityCount; i++) otherCategories.add('security');
      for (int i = 0; i < negativeCount; i++) otherCategories.add('negative');
    } else if (_negativeFocused) {
      happyCount = (count * 0.5).floor();
      otherCount = count - happyCount;
      otherCategories = ['negative', 'validation', 'boundary'];
    } else if (_sessionFocused) {
      happyCount = (count * 0.6).floor();
      otherCount = count - happyCount;
      otherCategories = ['session', 'negative'];
    } else {
      // Default 80% positive, 20% others
      happyCount = (count * 0.8).floor();
      otherCount = count - happyCount;
      otherCategories = ['negative', 'validation', 'boundary'];
    }

    // Build category list with minimum guarantees (Fix #13)
    final categories = <String>[];

    // Minimum guarantees per mode
    if (mode == GenerationMode.core) {
      // Core: at least 1 negative, 1 validation
      categories.add('negative');
      categories.add('validation');
      int remainingOther = otherCount - 2;
      if (remainingOther > 0) {
        for (int i = 0; i < remainingOther; i++) {
          categories.add(otherCategories[i % otherCategories.length]);
        }
      }
    } else if (mode == GenerationMode.pro) {
      // Pro: at least 1 negative, 1 validation, 1 boundary
      categories.add('negative');
      categories.add('validation');
      categories.add('boundary');
      int remainingOther = otherCount - 3;
      if (remainingOther > 0) {
        for (int i = 0; i < remainingOther; i++) {
          categories.add(otherCategories[i % otherCategories.length]);
        }
      }
    } else {
      // Fallback: just use otherCategories as before
      for (int i = 0; i < otherCount; i++) {
        categories.add(otherCategories[i % otherCategories.length]);
      }
    }

    // Add positive cases
    for (int i = 0; i < happyCount; i++) categories.add('positive');

    // Ensure exact count (trim if overshoot)
    while (categories.length < count) categories.add('positive');
    if (categories.length > count) categories.removeRange(count, categories.length);

    // Deterministic shuffle
    categories.sort((a, b) {
      final ha = StableHash.forText('$stableSeed|$a', 999999);
      final hb = StableHash.forText('$stableSeed|$b', 999999);
      return ha.compareTo(hb);
    });

    final businessArea = _businessArea;
    for (final category in categories) {
      final candidates = IntentRegistry.findByCategory(category)
          .where((i) => i.businessArea == businessArea)
          .toList();
      if (candidates.isEmpty) {
        skeletons.add({
          'intent_id': '${category}_generic',
          'category': category,
          'priority': _priorityFor(category),
          'risk': _riskFor(category),
          'business_area': businessArea,
        });
        continue;
      }
      // Pick a deterministic intent, avoid duplicates (Fix #14 support)
      String? selectedId;
      // First try to find an unused intent
      for (final intent in candidates) {
        if (!usedIntents.contains(intent.id)) {
          selectedId = intent.id;
          break;
        }
      }
      // If all used, pick first (allowed after pool exhausted)
      selectedId ??= candidates.first.id;

      usedIntents.add(selectedId);
      final intent = IntentRegistry.get(selectedId)!;
      skeletons.add({
        'intent_id': selectedId,
        'category': category,
        'priority': _priorityFor(category),
        'risk': intent.risk,
        'business_area': businessArea,
      });
    }

    // Ensure exact count (fill with generic if still missing)
    while (skeletons.length < count) {
      skeletons.add({
        'intent_id': 'positive_generic',
        'category': 'positive',
        'priority': 'Medium',
        'risk': 'LOW',
        'business_area': businessArea,
      });
    }
    if (skeletons.length > count) skeletons.removeRange(count, skeletons.length);

    return skeletons;
  }

  String _priorityFor(String category) {
    if (category == 'security' || category == 'session') return 'High';
    if (category == 'negative') return 'Medium';
    if (category == 'validation' || category == 'boundary') return 'Medium';
    return 'Low';
  }

  String _riskFor(String category) {
    if (category == 'security' || category == 'session') return 'HIGH';
    if (category == 'negative') return 'MEDIUM';
    return 'LOW';
  }
}