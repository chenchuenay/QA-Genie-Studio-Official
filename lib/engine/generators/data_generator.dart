import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../ontology/domain_data.dart';
import '../../core/utils/test_data_factory.dart';

class DataGenerator {
  static Map<String, String> generate(Scenario scenario, String constraints, {String platform = 'Web'}) {
    final data = <String, String>{};
    final action = scenario.action;
    final entity = scenario.entity;

    if (action == ActionType.login || action == ActionType.authenticate) {
      data['email'] = TestDataFactory.validEmail();
      data['password'] = TestDataFactory.validPassword();
      data['platform'] = platform;
    } else if (action == ActionType.refresh) {
      data['refresh_token'] = TestDataFactory.refreshTokenValid();
    } else if (action == ActionType.pay) {
      data['card_number'] = TestDataFactory.creditCardNumber();
      data['expiry'] = TestDataFactory.expiryDate();
      data['cvv'] = TestDataFactory.cvv();
    } else if (action == ActionType.apply && entity == EntityType.coupon) {
      data['coupon_code'] = TestDataFactory.validCoupon();
    } else if (action == ActionType.transfer) {
      data['amount'] = TestDataFactory.validAmount();
      data['beneficiary'] = TestDataFactory.beneficiary();
      data['from_account'] = 'Savings XXXX-8901';
      data['to_account'] = 'Checking XXXX-3456';
    } else if (action == ActionType.create && entity == EntityType.appointment) {
      data['slot'] = 'slot_available';
      data['date'] = '2026-07-15';
      data['time'] = '10:00 AM';
      data['provider'] = 'Dr. Smith';
    } else if (action == ActionType.book) {
      data['date'] = '2026-07-15';
      data['time'] = '10:00 AM';
      data['provider'] = 'Dr. Emily Smith';
      data['reason'] = 'Annual checkup';
    } else if (action == ActionType.reset) {
      data['email'] = TestDataFactory.validEmail('reset');
      data['new_password'] = 'NewSecure@789';
      data['confirm_password'] = 'NewSecure@789';
    } else if (action == ActionType.verify) {
      data['otp'] = TestDataFactory.validOtp();
      data['token'] = TestDataFactory.validToken();
    } else if (action == ActionType.add && entity == EntityType.item) {
      data['product'] = 'Wireless Headphones SKU-7755';
      data['quantity'] = '1';
      data['price'] = '49.99';
    } else if (action == ActionType.remove) {
      data['item_id'] = 'item_001';
    } else if (action == ActionType.checkout) {
      data['shipping_address'] = '123 Main St, Springfield, IL 62701';
      data['payment_method'] = 'VISA-4242';
      data['items'] = '2 items in cart';
    } else if (action == ActionType.cancel) {
      data['reason'] = 'Schedule conflict';
      data['entity_id'] = 'APPT-2026-0715-001';
    } else if (action == ActionType.reschedule) {
      data['new_date'] = '2026-07-16';
      data['new_time'] = '11:00 AM';
      data['appointment_id'] = 'APPT-2026-0715-001';
    } else if (action == ActionType.send) {
      data['endpoint'] = TestDataFactory.endpointValid();
      data['payload'] = TestDataFactory.payloadValid();
      data['api_key'] = TestDataFactory.apiKeyValid();
    } else if (action == ActionType.trigger) {
      data['webhook_url'] = 'https://api.example.com/hooks/v1/trigger';
      data['event_type'] = 'order.created';
      data['signature'] = 'hmac-sha256-valid-signature';
    } else if (action == ActionType.create && entity == EntityType.record) {
      data['patient_name'] = 'Jane Doe';
      data['dob'] = '1995-03-22';
      data['mrn'] = 'MRN-2026-8842';
      data['visit_reason'] = 'Annual physical examination';
    } else if (action == ActionType.update && entity == EntityType.record) {
      data['record_id'] = 'REC-2026-0042';
      data['field'] = 'diagnosis';
      data['new_value'] = 'Updated diagnosis text';
    } else if (action == ActionType.delete) {
      data['entity_id'] = 'TEST_${entity.name.toUpperCase()}_001';
      data['confirmation'] = 'DELETE';
    } else if (action == ActionType.view) {
      data['entity_id'] = 'TEST_${entity.name.toUpperCase()}_001';
      data['scope'] = 'full_detail';
    }

    _applyCondition(scenario, data);

    // Legacy constraint-based injection for security payloads
    final lower = constraints.toLowerCase();
    if (lower.contains('sql') && !data.containsKey('sql_payload'))
      data['sql_payload'] = TestDataFactory.sqlInjection();
    if (lower.contains('xss') && !data.containsKey('xss_payload'))
      data['xss_payload'] = TestDataFactory.xssPayload();

    if (data.isEmpty) {
      data['entity_id'] = 'TEST_${entity.name.toUpperCase()}_001';
    }

    _addDomainSamples(data, action, entity);

    return data;
  }

  static void _applyCondition(Scenario scenario, Map<String, String> data) {
    final condition = scenario.condition;
    if (condition == 'valid' || condition.isEmpty) return;

    if (scenario.category == 'security') {
      switch (condition) {
        case 'sql_injection':
          data['payload'] = TestDataFactory.sqlInjection();
          data['input_type'] = 'malicious_sql';
          data['expected_response'] = '400';
        case 'xss':
          data['payload'] = TestDataFactory.xssPayload();
          data['input_type'] = 'malicious_xss';
          data['expected_response'] = '400';
        case 'bruteforce':
          data['password_attempt'] = 'wrong_password_1';
          data['max_attempts'] = '5';
          data['lockout_duration'] = '15 minutes';
        case 'jwt_hijack':
          data['token'] = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhdHRhY2tlciJ9.forged';
          data['token_type'] = 'forged_jwt';
          data['expected_response'] = '401';
        case 'masquerade':
          data['user_id'] = 'attacker_user';
          data['impersonated_user'] = 'admin@example.com';
          data['expected_response'] = '403';
        default:
          data['malicious_input'] = '${condition}_payload';
          data['expected_response'] = '400';
      }
    } else if (scenario.category == 'validation') {
      switch (condition) {
        case 'special_chars':
          data['input'] = '<script>alert("xss")</script>@!#\$%^&*()';
        case 'unusual':
          data['input'] = r'ñöñ-Å$ÇÍÍ-𝓤𝓷𝓲𝓬𝓸𝓭𝓮';
        case 'extremely_long':
          data['input'] = 'A' * 10000;
        case 'invalid_format':
          data['input'] = 'not-an-email';
          data['format'] = 'email';
        case 'empty':
          data['input'] = '';
        default:
          data['input'] = condition;
      }
    } else if (scenario.category == 'boundary') {
      switch (condition) {
        case 'empty':
          data['input'] = '';
        case 'max_length':
          data['input'] = 'A' * 255;
          data['max_allowed'] = '255';
        case 'min_value':
          data['input'] = '0';
          data['note'] = 'minimum boundary value';
        case 'max_value':
          data['input'] = '9999999999';
          data['note'] = 'overflow boundary value';
        case 'exceed':
          data['input'] = 'A' * 256;
          data['max_allowed'] = '255';
          data['expected_response'] = 'error';
        default:
          data['input'] = condition;
      }
    } else if (scenario.category == 'session') {
      switch (condition) {
        case 'expired':
          data['session_token'] = 'expired_token_abc123';
          data['session_status'] = 'expired';
          data['expected_response'] = '401';
        case 'revoked':
          data['session_token'] = 'revoked_token_def456';
          data['session_status'] = 'revoked';
          data['expected_response'] = '403';
        case 'stale':
          data['refresh_token'] = 'stale_refresh_token_xyz789';
          data['expected_response'] = '401';
        case 'invalid':
          data['session_cookie'] = 'tampered_cookie_value';
          data['expected_response'] = '401';
        default:
          data['session_state'] = condition;
          data['expected_response'] = '401';
      }
    }
  }

  static void _addDomainSamples(Map<String, String> data, ActionType action, EntityType entity) {
    final domain = _domainForAction(action, entity);
    final samples = DomainData.samples[domain] ?? {};
    if (samples.isNotEmpty) {
      final sampleKeys = samples.keys.take(3);
      for (final key in sampleKeys) {
        if (!data.containsKey(key.toLowerCase())) {
          data['sample_$key'] = samples[key]!;
        }
      }
    }
  }

  static String _domainForAction(ActionType action, EntityType entity) {
    if (action == ActionType.login || action == ActionType.authenticate || action == ActionType.refresh || action == ActionType.reset) {
      return 'Identity';
    }
    if (action == ActionType.add || action == ActionType.remove || action == ActionType.checkout || action == ActionType.pay) {
      return 'Commerce';
    }
    if (action == ActionType.transfer || action == ActionType.deposit || action == ActionType.withdraw) {
      return 'Transaction';
    }
    if (action == ActionType.create || action == ActionType.book || action == ActionType.reschedule || action == ActionType.cancel) {
      return 'Scheduling';
    }
    if (entity == EntityType.record || entity == EntityType.prescription || entity == EntityType.labResult) {
      return 'Records';
    }
    if (action == ActionType.send || action == ActionType.trigger || action == ActionType.webhookTrigger) {
      return 'Integration';
    }
    return 'Identity';
  }
}
