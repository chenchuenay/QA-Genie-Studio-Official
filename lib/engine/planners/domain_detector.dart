import '../models/domain_context.dart';
import '../domains/records_domain.dart';
import '../domains/identity_domain.dart';
import '../domains/commerce_domain.dart';
import '../domains/scheduling_domain.dart';
import '../domains/transaction_domain.dart';
import '../domains/integration_domain.dart';

class DomainDetector {
  static DomainContext detect(String module, String feature) {
    final combined = '$module $feature'.toLowerCase();

    // Simple keyword matching – order matters (more specific first)
    if (_containsAny(combined, [
      'appointment',
      'schedule',
      'provider',
      'patient',
      'slot',
      'calendar',
      'booking',
      'telehealth',
    ])) {
      return SchedulingDomain.context;
    }
    if (_containsAny(combined, [
      'login',
      'signin',
      'sign in',
      'auth',
      'authenticate',
      'password',
      'session',
      'token',
      'mfa',
      'otp',
      'logout',
    ])) {
      return IdentityDomain.context;
    }
    if (_containsAny(combined, [
      'cart',
      'checkout',
      'order',
      'coupon',
      'gift card',
      'shipping',
      'address',
      'payment',
      'item',
      'product',
    ])) {
      return CommerceDomain.context;
    }
    if (_containsAny(combined, [
      'wallet',
      'transfer',
      'transaction',
      'balance',
      'payee',
      'beneficiary',
      'deposit',
      'withdraw',
    ])) {
      return TransactionDomain.context;
    }
    if (_containsAny(combined, [
      'record',
      'lab',
      'prescription',
      'consent',
      'insurance',
      'document',
      'result',
    ])) {
      return RecordsDomain.context;
    }
    if (_containsAny(combined, [
      'webhook',
      'api',
      'endpoint',
      'integration',
      'callback',
      'event',
    ])) {
      return IntegrationDomain.context;
    }
    if (_containsAny(combined, [
      'robot',
      'fleet',
      'drone',
      'sensor',
      'actuator',
      'mission',
      'waypoint',
      'calibrate',
    ])) {
      return SchedulingDomain.context;
    }
    if (_containsAny(combined, [
      'ai',
      'machine learning',
      'model training',
      'prediction',
      'dataset',
      'deploy',
      'server',
      'container',
      'devops',
      'infrastructure',
    ])) {
      return CommerceDomain.context;
    }
    if (_containsAny(combined, [
      'social',
      'post',
      'feed',
      'message',
      'chat',
      'notification',
    ])) {
      return CommerceDomain.context;
    }
    // Fallback to commerce (most common generic)
    return CommerceDomain.context;
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((kw) => text.contains(kw));
  }
}
