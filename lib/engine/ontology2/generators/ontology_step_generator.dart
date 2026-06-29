import 'dart:math';

import '../model/entity_def.dart';
import '../model/action_def.dart';
import '../model/step_template.dart';
import '../model/domain_ontology.dart';
import 'ontology_data_generator.dart';

class OntologyStepGenerator {
  static List<String> generate(
    String category,
    String condition,
    bool isPositive,
    EntityDef entity,
    ActionDef action,
    DomainOntology domain, {
    String platform = 'Web',
    int seed = 0,
  }) {
    final rng = Random(seed);
    final steps = <String>[];
    final data = OntologyDataGenerator.generate(
      category, condition, isPositive, entity, action,
      platform: platform, seed: seed,
    );

    final isWeb = platform == 'Web';
    final isApi = platform == 'API';
    final navVariant = isApi ? 'api' : (isWeb ? 'web' : 'mobile');
    final execVariant = isApi ? 'api' : (isWeb ? 'web' : 'mobile');

    _addConditionStep(steps, condition, isPositive, entity, action, data, rng);
    _addActionSteps(steps, condition, entity, action, data, navVariant, execVariant, isApi, rng);
    _addVerificationStep(steps, isPositive, entity, action, isApi, rng);

    return steps;
  }

  static void _addConditionStep(
    List<String> steps,
    String condition,
    bool isPositive,
    EntityDef entity,
    ActionDef action,
    Map<String, String> data,
    Random rng,
  ) {
    if (condition == 'valid' || isPositive) return;

    final entityLabel = entity.displayName;
    final propList = action.requiredPropertyNames.map((n) {
      final p = entity.property(n);
      return p?.effectiveLabel ?? n;
    }).toList();

    switch (condition) {
      case 'empty':
        steps.add('Intentionally leave the ${propList.join(", ")} field(s) blank and attempt to submit the $entityLabel form');
      case 'invalid_format':
        steps.add('Enter a malformed value (e.g. invalid_email@ or 12345) in the ${propList.join(", ")} field(s)');
      case 'sql_injection':
        steps.add("Inject a malicious SQL payload ' OR 1=1; -- into the ${propList.join(", ")} field(s) and submit");
      case 'xss':
        steps.add('Inject an XSS payload <script>alert("xss")</script> into the ${propList.join(", ")} field(s) and submit');
      case 'csrf_mismatch':
        steps.add('Tamper with the CSRF state parameter, substituting a forged value instead of the legitimate one');
      case 'oauth_replay':
        steps.add('Intercept the authorization code from a successful OAuth flow, then replay it in a new authorization request');
      case 'expired_code':
        steps.add('Wait for the authorization code expiration window to elapse, then submit the expired code');
      case 'max_length':
        steps.add('Enter input exceeding the character limit (${data.values.firstOrNull?.length ?? 256} characters) into the ${propList.join(", ")} field(s)');
      case 'max_redirect_uri':
        steps.add('Configure the redirect URI length to exceed the maximum allowed length of 2048 characters');
      case 'expired':
        steps.add('Use an expired $entityLabel token or session');
      case 'revoked':
        steps.add('Use a revoked $entityLabel token or session');
      case 'invalid':
        steps.add('Use invalid credentials for the ${action.displayName} attempt');
      case 'bruteforce':
        steps.add('Repeatedly attempt authentication with incorrect credentials to trigger lockout protection');
      default:
        steps.add('Set up the $condition condition for the ${action.displayName} operation on the $entityLabel');
    }
  }

  static void _addActionSteps(
    List<String> steps,
    String condition,
    EntityDef entity,
    ActionDef action,
    Map<String, String> data,
    String navVariant,
    String execVariant,
    bool isApi,
    Random rng,
  ) {
    final entityLabel = entity.displayName;
    final actionVerb = action.displayName;

    switch (action.id) {
      case 'login':
        steps.add(_pickNav('login page', navVariant, rng));
        _addInputSteps(steps, entity, data, isApi, rng);
        steps.add(_pickExec('Log in', 'Sign In', execVariant, rng));
        break;
      case 'logout':
        steps.add(_pickNav('dashboard/home page', navVariant, rng));
        steps.add('Locate the avatar or profile menu in the top-right corner');
        steps.add(_pickExec('Log out', 'Sign Out', execVariant, rng));
        break;
      case 'authenticate':
        steps.add(_pickNav('authentication page', navVariant, rng));
        _addInputSteps(steps, entity, data, isApi, rng);
        steps.add(_pickExec('Authenticate', 'Submit', execVariant, rng));
        break;
      case 'authorize':
        steps.add(_pickNav('OAuth authorization endpoint', navVariant, rng));
        steps.add('Select the identity provider and grant consent for the requested scopes');
        break;
      case 'refresh':
        steps.add('Initiate a token refresh request using the current refresh token');
        break;
      case 'reset':
        steps.add(_pickNav('password reset page', navVariant, rng));
        steps.add('Enter the reset token or follow the link from the email');
        _addInputSteps(steps, entity, data, isApi, rng);
        steps.add(_pickExec('Reset password', 'Update Password', execVariant, rng));
        break;
      case 'verify':
        steps.add(_pickNav('verification page', navVariant, rng));
        steps.add('Enter the OTP verification code');
        steps.add(_pickExec('Verify', 'Confirm', execVariant, rng));
        break;
      default:
        steps.add(_pickNav('$actionVerb $entityLabel section', navVariant, rng));
        _addInputSteps(steps, entity, data, isApi, rng);
        steps.add(_pickExec(actionVerb, actionVerb, execVariant, rng));
    }
  }

  static String _pickNav(String destination, String variant, Random rng) {
    return VariationPool.pick('navigate', variant, {'entity': destination}, rng);
  }

  static String _pickExec(String primary, String fallback, String variant, Random rng) {
    final action = rng.nextBool() ? primary : fallback;
    return VariationPool.pick('execute', variant, {'button': action}, rng);
  }

  static void _addInputSteps(
    List<String> steps,
    EntityDef entity,
    Map<String, String> data,
    bool isApi,
    Random rng,
  ) {
    for (final entry in data.entries) {
      final prop = entity.property(entry.key);
      final label = prop?.effectiveLabel ?? entry.key;
      final value = entry.value;
      if (value.isEmpty) continue;
      if (isApi) {
        steps.add(VariationPool.pick('input', 'api', {'key': label, 'value': value}, rng));
      } else if (prop?.isSensitive == true) {
        steps.add(VariationPool.pick('input', 'sensitive', {'label': label}, rng));
      } else if (prop?.isIdentifier == true) {
        steps.add(VariationPool.pick('input', 'identifier', {'label': label, 'value': value}, rng));
      } else {
        steps.add(VariationPool.pick('input', 'text', {'label': label, 'value': value}, rng));
      }
    }
  }

  static void _addVerificationStep(
    List<String> steps,
    bool isPositive,
    EntityDef entity,
    ActionDef action,
    bool isApi,
    Random rng,
  ) {
    if (isApi) {
      final status = isPositive ? '200' : '400';
      steps.add(VariationPool.pick('verify', 'api', {'status': status}, rng));
      return;
    }

    if (isPositive) {
      steps.add(VariationPool.pick('verify', 'success', {'outcome': 'the operation completes successfully'}, rng));
    } else {
      final msg = 'an error message is displayed and the state remains unchanged';
      steps.add(VariationPool.pick('verify', 'error', {'message': msg}, rng));
    }
  }
}
