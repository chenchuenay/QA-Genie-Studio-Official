import 'package:qa_genie/engine/business/business_area.dart';
import 'package:qa_genie/engine/adapters/platform_adapter.dart';

class ObservationGenerator {
  static List<String> generate({
    required String outcome,
    required EntityType entity,
    required String platform,
    required BusinessArea businessArea,
  }) {
    final observations = <String>[];
    final isPositive =
        !outcome.contains('invalid') &&
        !outcome.contains('empty') &&
        !outcome.contains('expired') &&
        !outcome.contains('fail');

    // Base outcome observation
    if (isPositive) {
      observations.add('Operation completed successfully.');
    } else {
      observations.add('Operation failed as expected.');
    }

    // Entity‑specific observations
    switch (entity) {
      case EntityType.sessionToken:
        observations.add('Session token is generated successfully.');
        break;
      case EntityType.dashboard:
        observations.add('Dashboard loads with user‑specific content.');
        break;
      case EntityType.order:
        observations.add('Order record is created and stored.');
        break;
      case EntityType.errorMessage:
        observations.add('Error message is clearly displayed to the user.');
        break;
      case EntityType.successIndicator:
        observations.add('Success confirmation appears on screen.');
        break;
      case EntityType.receipt:
        observations.add('Transaction receipt is generated.');
        break;
      default:
        observations.add('Expected system state is reached.');
    }

    // Business area specific – only for exact outcomes
    if (businessArea.id == 'authentication') {
      if (outcome == 'social_login') {
        observations.add('Provider account is linked to the user profile.');
      } else if (outcome == 'mfa_login') {
        observations.add('Multi‑factor verification is enforced and passed.');
      }
    } else if (businessArea.id == 'ecommerce') {
      if (outcome == 'valid_checkout') {
        observations.add(
          'Inventory is updated. Payment transaction is recorded.',
        );
      }
    }

    return observations;
  }
}
