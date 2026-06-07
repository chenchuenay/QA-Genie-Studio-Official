import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/adapters/platform_adapter.dart';

class ObservationGenerator {
  static List<Map<String, dynamic>> generate({
    required String outcome,
    required EntityType entity,
    required String platform,
    required BusinessArea businessArea,
    required String module,
    required String feature,
    required String constraints,
  }) {
    final hasConstraint = constraints.trim().isNotEmpty;
    if (hasConstraint) {
      final intent = _parseConstraintIntent(constraints.toLowerCase());
      if (intent != null) {
        return _observationsForIntent(
          intent,
          outcome,
          entity,
          platform,
          businessArea,
          feature,
        );
      }
    }

    // ──────────────────────────────────────────────────────────
    // NORMAL MODE (no constraint or unknown intent)
    // ──────────────────────────────────────────────────────────
    return _normalObservations(
      outcome,
      entity,
      platform,
      businessArea,
      feature,
    );
  }

  // ========== INTENT PARSING ==========
  static String? _parseConstraintIntent(String constraints) {
    // Positive / happy path
    if (constraints.contains('positive') ||
        constraints.contains('happy path') ||
        constraints.contains('success')) {
      return 'positive';
    }
    // Negative / failure
    if (constraints.contains('negative') ||
        constraints.contains('failure') ||
        constraints.contains('error')) {
      return 'negative';
    }
    // Validation
    if (constraints.contains('validation') ||
        constraints.contains('invalid input') ||
        constraints.contains('empty')) {
      return 'validation';
    }
    // Edge / boundary
    if (constraints.contains('edge') ||
        constraints.contains('boundary') ||
        constraints.contains('limit')) {
      return 'edge';
    }
    // Security
    if (constraints.contains('security') ||
        constraints.contains('sql') ||
        constraints.contains('xss')) {
      return 'security';
    }
    // Session
    if (constraints.contains('session') ||
        constraints.contains('timeout') ||
        constraints.contains('expiry')) {
      return 'session';
    }
    // Social login / Gmail
    if (constraints.contains('gmail') ||
        constraints.contains('google') ||
        constraints.contains('oauth') ||
        constraints.contains('social')) {
      return 'social';
    }
    // Ecommerce
    if (constraints.contains('checkout') ||
        constraints.contains('payment') ||
        constraints.contains('order')) {
      return 'ecommerce';
    }
    // Banking
    if (constraints.contains('transfer') ||
        constraints.contains('banking') ||
        constraints.contains('balance')) {
      return 'banking';
    }
    return null;
  }

  // ========== INTENT‑SPECIFIC OBSERVATIONS ==========
  static List<Map<String, dynamic>> _observationsForIntent(
    String intent,
    String outcome,
    EntityType entity,
    String platform,
    BusinessArea businessArea,
    String feature,
  ) {
    switch (intent) {
      case 'positive':
        return [
          {
            'text': 'Operation completes successfully.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'negative':
        return [
          {
            'text': 'Operation fails with appropriate error feedback.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'validation':
        return [
          {
            'text': 'Invalid input is rejected and validation error is shown.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'edge':
        return [
          {
            'text': 'Edge cases are handled correctly without crashes.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'security':
        return [
          {
            'text':
                'Malicious input is rejected and security validation is enforced.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'session':
        return [
          {
            'text':
                'Session state is managed correctly; user is redirected or notified.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'social':
        return [
          {
            'text':
                'Social login flow completes; user is redirected to the application.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'ecommerce':
        return [
          {
            'text': 'Order is processed and confirmation is displayed.',
            'score': 100,
            'type': 'intent',
          },
        ];
      case 'banking':
        return [
          {
            'text': 'Transaction is processed and balance is updated.',
            'score': 100,
            'type': 'intent',
          },
        ];
      default:
        return _normalObservations(
          outcome,
          entity,
          platform,
          businessArea,
          feature,
        );
    }
  }

  // ========== NORMAL OBSERVATIONS (original scoring logic) ==========
  static List<Map<String, dynamic>> _normalObservations(
    String outcome,
    EntityType entity,
    String platform,
    BusinessArea businessArea,
    String feature,
  ) {
    final isPositive =
        !outcome.contains('invalid') &&
        !outcome.contains('empty') &&
        !outcome.contains('expired') &&
        !outcome.contains('fail');
    final baseScore = isPositive ? 10 : 5;
    final observations = <Map<String, dynamic>>[];

    // Platform‑specific UI observations
    if (platform == 'Web') {
      observations.addAll(_webObservations(entity, isPositive, baseScore));
    } else if (platform == 'Mobile') {
      observations.addAll(_mobileObservations(entity, isPositive, baseScore));
    } else if (platform == 'API') {
      observations.addAll(_apiObservations(entity, isPositive, baseScore));
    } else {
      observations.add({
        'text': 'System transitions to the expected state.',
        'score': baseScore + 10,
        'type': 'ui',
      });
    }

    // Business effects
    if (businessArea.id == 'authentication') {
      if (isPositive &&
          (outcome.contains('valid') ||
              outcome == 'social_login' ||
              outcome == 'mfa_login')) {
        observations.add({
          'text': 'User is authenticated and session is created.',
          'score': baseScore + 15,
          'type': 'business',
        });
      } else if (!isPositive) {
        observations.add({
          'text':
              'User remains unauthenticated and cannot access protected pages.',
          'score': baseScore + 12,
          'type': 'business',
        });
      }
    } else if (businessArea.id == 'ecommerce') {
      if (isPositive && outcome == 'valid_checkout') {
        observations.add({
          'text': 'Order is placed and inventory is updated.',
          'score': baseScore + 15,
          'type': 'business',
        });
      } else if (!isPositive) {
        observations.add({
          'text': 'Order is not placed, cart remains unchanged.',
          'score': baseScore + 12,
          'type': 'business',
        });
      }
    } else if (businessArea.id == 'banking') {
      if (isPositive) {
        observations.add({
          'text': 'Transaction is processed and balance is updated.',
          'score': baseScore + 15,
          'type': 'business',
        });
      }
    }

    // Generic fallback
    if (isPositive) {
      observations.add({
        'text': 'Operation completes without errors.',
        'score': baseScore + 5,
        'type': 'generic',
      });
    } else {
      observations.add({
        'text': 'Operation fails with appropriate feedback.',
        'score': baseScore + 5,
        'type': 'generic',
      });
    }

    return observations;
  }

  // Platform helpers (unchanged from previous version)
  static List<Map<String, dynamic>> _webObservations(
    EntityType entity,
    bool isPositive,
    int baseScore,
  ) {
    switch (entity) {
      case EntityType.successIndicator:
        return [
          {
            'text': 'Success message appears on the page.',
            'score': baseScore + 20,
            'type': 'ui',
          },
        ];
      case EntityType.errorMessage:
        return [
          {
            'text': 'Error message is displayed inline.',
            'score': baseScore + 20,
            'type': 'ui',
          },
        ];
      case EntityType.dashboard:
        return [
          {
            'text': 'Dashboard page loads with user‑specific content.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      case EntityType.receipt:
        return [
          {
            'text': 'Receipt page is shown with transaction details.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      case EntityType.order:
        return [
          {
            'text': 'Order confirmation page appears.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      default:
        return [
          {
            'text': 'Browser remains on the current page with updated content.',
            'score': baseScore + 10,
            'type': 'ui',
          },
        ];
    }
  }

  static List<Map<String, dynamic>> _mobileObservations(
    EntityType entity,
    bool isPositive,
    int baseScore,
  ) {
    switch (entity) {
      case EntityType.successIndicator:
        return [
          {
            'text': 'Success toast or modal appears.',
            'score': baseScore + 20,
            'type': 'ui',
          },
        ];
      case EntityType.errorMessage:
        return [
          {
            'text': 'Error dialog or inline message is shown.',
            'score': baseScore + 20,
            'type': 'ui',
          },
        ];
      case EntityType.dashboard:
        return [
          {
            'text': 'Dashboard screen loads with user data.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      case EntityType.receipt:
        return [
          {
            'text': 'Receipt screen is displayed.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      case EntityType.order:
        return [
          {
            'text': 'Order confirmation screen appears.',
            'score': baseScore + 25,
            'type': 'ui',
          },
        ];
      default:
        return [
          {
            'text': 'Screen remains responsive and updates accordingly.',
            'score': baseScore + 10,
            'type': 'ui',
          },
        ];
    }
  }

  static List<Map<String, dynamic>> _apiObservations(
    EntityType entity,
    bool isPositive,
    int baseScore,
  ) {
    if (isPositive) {
      return [
        {
          'text': 'API returns 200 OK with expected data.',
          'score': baseScore + 25,
          'type': 'ui',
        },
      ];
    } else {
      return [
        {
          'text': 'API returns error status code (4xx/5xx) with error details.',
          'score': baseScore + 25,
          'type': 'ui',
        },
      ];
    }
  }
}
