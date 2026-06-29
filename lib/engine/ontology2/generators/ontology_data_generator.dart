import 'dart:math';

import '../model/entity_def.dart';
import '../model/action_def.dart';

class OntologyDataGenerator {
  static Map<String, String> generate(
    String category,
    String condition,
    bool isPositive,
    EntityDef entity,
    ActionDef action, {
    String platform = 'Web',
    int seed = 0,
  }) {
    final data = <String, String>{};
    final rng = Random(seed);

    for (final propName in action.requiredPropertyNames) {
      final prop = entity.property(propName);
      if (prop == null) continue;
      data[prop.name] = _valueForCondition(prop, condition, rng);
    }

    for (final propName in action.optionalPropertyNames) {
      final prop = entity.property(propName);
      if (prop == null) continue;
      if (rng.nextBool()) {
        data[prop.name] = _valueForCondition(prop, condition, rng);
      }
    }

    _applySecurityData(data, condition);

    return data;
  }

  static String _valueForCondition(PropertyDef prop, String condition, Random rng) {
    switch (condition) {
      case 'valid':
      case 'minimum':
        return prop.example ?? 'valid_${prop.name}';
      case 'invalid':
      case 'invalid_format':
        return prop.invalidExample ?? 'invalid_${prop.name}';
      case 'empty':
        return '';
      case 'max_length':
        return 'A' * (prop.maxLength ?? 255);
      case 'max_redirect_uri':
        if (prop.type == PropertyType.url) {
          return 'https://app.example.com/' + ('a' * 2024);
        }
        return prop.boundaryHigh ?? 'A' * 1000;
      case 'maximum':
        return prop.boundaryHigh ?? prop.example ?? 'max_${prop.name}';
      case 'sql_injection':
        return "' OR 1=1; --";
      case 'xss':
        return '<script>alert("xss")</script>';
      case 'csrf_mismatch':
        if (prop.name == 'state') return 'attacker_csrf_token';
        return prop.example ?? prop.name;
      case 'oauth_replay':
        if (prop.name == 'authCode') return 'USED_CODE_REPLAY';
        return prop.example ?? prop.name;
      case 'expired_code':
        if (prop.name == 'authCode') return 'EXPIRED_CODE_xyz789';
        return prop.example ?? prop.name;
      case 'expired':
        if (prop.type == PropertyType.token) return 'expired_${prop.example ?? 'token'}';
        return prop.example ?? prop.name;
      case 'revoked':
        if (prop.type == PropertyType.token) return 'revoked_${prop.example ?? 'token'}';
        return prop.example ?? prop.name;
      default:
        return prop.example ?? '${condition}_${prop.name}';
    }
  }

  static void _applySecurityData(Map<String, String> data, String condition) {
    switch (condition) {
      case 'sql_injection':
        if (!data.containsKey('payload')) data['payload'] = "' OR 1=1; --";
        if (!data.containsKey('input_type')) data['input_type'] = 'malicious_sql';
        if (!data.containsKey('expected_response')) data['expected_response'] = '400';
      case 'xss':
        if (!data.containsKey('payload')) data['payload'] = '<script>alert("xss")</script>';
        if (!data.containsKey('input_type')) data['input_type'] = 'malicious_xss';
        if (!data.containsKey('expected_response')) data['expected_response'] = '400';
    }
  }
}
