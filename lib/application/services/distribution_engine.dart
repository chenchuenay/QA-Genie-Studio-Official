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

    // --- Category Balancing and Prioritization ---
    final categoriesToPromote = [
      'session', 'permissions', 'network_behavior', 'state_persistence',
      'navigation', 'accessibility', 'usability'
    ];
    // Removed unused variable 'categoriesToLimit'
    
    final isProMode = count > 10;

    // 1. Prioritize unused categories (if any are available and not already over-represented)
    // This is a lightweight approach: if we have capacity, try to fill with promoted categories.
    // A more sophisticated approach would track usage and explicitly fill ununsed ones first.

    // 2. Limit overuse of generic negative/security cases
    if (isProMode) {
      final limitedNegativeCount = isApi ? 2 : 3; // Reduce generic negative for API
      if (dist['negative'] != null && dist['negative']! > limitedNegativeCount) {
        dist['negative'] = limitedNegativeCount;
      }
      if (dist['security'] != null && dist['security']! > limitedNegativeCount) {
        dist['security'] = limitedNegativeCount;
      }
    }

    // 3. Ensure broader usage of promoted categories
    int availableCapacity = count - dist.values.fold(0, (a, b) => a + b);
    if (availableCapacity > 0) {
      for (final cat in categoriesToPromote) {
        if (availableCapacity <= 0) break;
        final currentCount = dist[cat] ?? 0;
        final desiredCount = isProMode ? 2 : 1; // Aim for at least 1-2 for promoted categories
        final toAdd = min(availableCapacity, desiredCount - currentCount);
        if (toAdd > 0) {
          dist[cat] = currentCount + toAdd;
          availableCapacity -= toAdd;
        }
      }
    }
    
    // Ensure total count matches target, adjust if necessary (e.g., from promoted categories)
    return _normalize(dist, count);
  }

  Map<String, int> _normalize(Map<String, int> dist, int target) {
    int sum = dist.values.fold(0, (a, b) => a + b);
    if (sum == target) return dist;

    // List of categories ordered by preference for reduction/addition
    // Categories to reduce first if sum > target
    List<String> reductionOrder = ['negative', 'security', 'validation', 'boundary', 'usability', 'positive'];
    // Categories to increase if sum < target (beyond promoted ones)
    List<String> additionOrder = ['positive', 'usability', 'boundary', 'validation', 'negative', 'security'];

    // Reduce counts if sum > target
    if (sum > target) {
      for (final cat in reductionOrder) {
        if (dist.containsKey(cat) && dist[cat]! > 0 && sum > target) {
          int reduce = min(dist[cat]!, sum - target);
          dist[cat] = dist[cat]! - reduce;
          sum -= reduce;
          if (sum == target) break;
        }
      }
    }

    // Increase counts if sum < target
    while (sum < target) {
      // Prioritize adding to 'positive' first, then others
      if (dist['positive'] != null && dist['positive']! < target * 0.7) { // Ensure positive remains dominant
          dist['positive'] = (dist['positive'] ?? 0) + 1;
      } else {
        for(final cat in additionOrder) {
          if (dist.containsKey(cat)) { // Add to existing categories if possible
            dist[cat] = (dist[cat] ?? 0) + 1;
            break;
          } else { // Add new category if it doesn't exist
            dist[cat] = 1;
          }
        }
      }
      sum++;
    }
    return dist;
  }
}