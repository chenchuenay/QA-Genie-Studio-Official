import 'dart:math';
import 'generation_mode.dart';

class DistributionEngine {
  final String module;
  final String feature;
  final String platform;
  final GenerationMode mode;
  final int count;
  final String domain;

  DistributionEngine({
    required this.module,
    required this.feature,
    required this.platform,
    required this.mode,
    required this.count,
    this.domain = 'general',
  });

  Map<String, int> calculate() {
    final combined = '$module $feature $domain'.toLowerCase();
    final isAuth = combined.contains('login') || combined.contains('signup') || combined.contains('password');
    final isPayment = combined.contains('payment') || combined.contains('checkout') || combined.contains('card');
    final isApi = platform == 'API';

    Map<String, int> dist;
    if (isApi) {
      dist = (count == 10)
          ? {'positive':2, 'negative':2, 'security':2, 'validation':2, 'boundary':1, 'session':1}
          : {'positive':4, 'negative':4, 'security':4, 'validation':4, 'boundary':2, 'session':2};
    } else if (isAuth) {
      dist = (count == 10)
          ? {'positive':2, 'negative':2, 'security':2, 'validation':2, 'boundary':1, 'session':1}
          : {'positive':4, 'negative':4, 'security':4, 'validation':4, 'boundary':2, 'session':2};
    } else if (isPayment) {
      dist = (count == 10)
          ? {'positive':2, 'negative':2, 'security':2, 'validation':2, 'boundary':1, 'session':1}
          : {'positive':4, 'negative':4, 'security':3, 'validation':3, 'boundary':3, 'session':3};
    } else {
      dist = (count == 10)
          ? {'positive':2, 'negative':2, 'validation':2, 'boundary':1, 'security':1, 'session':1, 'usability':1}
          : {'positive':4, 'negative':4, 'validation':3, 'boundary':3, 'security':3, 'session':2, 'usability':1};
    }

    if (mode == GenerationMode.positiveOnly) dist.updateAll((k, v) => k == 'positive' ? count : 0);
    else if (mode == GenerationMode.securityFocused) {
      dist['security'] = (count * 0.5).ceil(); dist['positive'] = (count * 0.3).ceil(); dist['negative'] = (count * 0.2).ceil();
      dist.remove('usability'); dist.remove('session');
    } else if (mode == GenerationMode.boundaryFocused) {
      dist['boundary'] = (count * 0.5).ceil(); dist['validation'] = (count * 0.3).ceil();
      dist.remove('usability'); dist.remove('session');
    } else if (mode == GenerationMode.validationOnly) dist.updateAll((k, v) => k == 'validation' ? count : 0);

    return _normalize(dist, count);
  }

  Map<String, int> _normalize(Map<String, int> dist, int target) {
    int sum = dist.values.fold(0, (a, b) => a + b);
    if (sum == target) return dist;
    List<String> order = ['usability', 'session', 'boundary', 'validation', 'positive', 'negative', 'security'];
    for (final cat in order) {
      if (dist.containsKey(cat) && dist[cat]! > 0 && sum > target) {
        int reduce = min(dist[cat]!, sum - target);
        dist[cat] = dist[cat]! - reduce; sum -= reduce;
        if (sum == target) break;
      }
    }
    while (sum < target) { dist['positive'] = (dist['positive'] ?? 0) + 1; sum++; }
    return dist;
  }
}
