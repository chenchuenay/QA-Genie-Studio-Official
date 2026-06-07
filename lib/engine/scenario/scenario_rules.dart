import 'package:qa_genie/engine/business/business_area.dart';

class ScenarioRules {
  static List<String> getOutcomes(BusinessArea businessArea, String category) {
    switch (businessArea.id) {
      case 'authentication':
        return _authenticationOutcomes(category);
      case 'ecommerce':
        return _ecommerceOutcomes(category);
      case 'banking':
        return _bankingOutcomes(category);
      case 'medical':
        return _medicalOutcomes(category);
      case 'telehealth':
        return _telehealthOutcomes(category);
      default:
        return _defaultOutcomes(category);
    }
  }

  static List<String> _authenticationOutcomes(String category) {
    switch (category) {
      case 'positive':
        return [
          'valid_login',
          'social_login',
          'mfa_login',
          'remembered_session',
        ];
      case 'negative':
        return ['invalid_password', 'locked_account', 'nonexistent_user'];
      case 'validation':
        return ['empty_email', 'empty_password', 'invalid_email_format'];
      case 'boundary':
        return ['max_email_length', 'max_password_length'];
      case 'security':
        return ['sql_injection', 'xss'];
      case 'session':
        return ['session_expiry', 'concurrent_login'];
      default:
        return ['generic_$category'];
    }
  }

  static List<String> _ecommerceOutcomes(String category) {
    switch (category) {
      case 'positive':
        return [
          'add_to_cart',
          'remove_from_cart',
          'update_quantity',
          'apply_coupon',
          'apply_gift_card',
          'valid_checkout',
        ];
      case 'negative':
        return [
          'invalid_coupon',
          'expired_coupon',
          'insufficient_stock',
          'payment_declined',
          'invalid_address',
          'shipping_error',
        ];
      case 'validation':
        return ['empty_cart', 'missing_payment_info', 'invalid_quantity'];
      case 'boundary':
        return ['max_items_exceeded', 'max_quantity_per_item'];
      case 'security':
        return ['price_tampering', 'quantity_overflow'];
      default:
        return ['ecom_${category}_generic'];
    }
  }

  static List<String> _bankingOutcomes(String category) {
    switch (category) {
      case 'positive':
        return [
          'view_balance',
          'add_payee',
          'delete_payee',
          'valid_transfer',
          'schedule_payment',
        ];
      case 'negative':
        return [
          'insufficient_funds',
          'invalid_payee',
          'transfer_limits_exceeded',
          'daily_limit_hit',
          'duplicate_transaction',
        ];
      case 'validation':
        return ['empty_amount', 'negative_amount', 'invalid_account_format'];
      case 'boundary':
        return ['min_amount_transfer', 'max_amount_transfer'];
      case 'security':
        return ['unauthorized_access', 'session_tampering'];
      default:
        return ['bank_${category}_generic'];
    }
  }

  static List<String> _medicalOutcomes(String category) {
    switch (category) {
      case 'positive':
        return [
          'schedule_appointment',
          'cancel_appointment',
          'reschedule_appointment',
          'prescription_refill_request',
          'view_lab_results',
        ];
      case 'negative':
        return [
          'invalid_insurance',
          'duplicate_booking',
          'provider_unavailable',
          'refill_too_early',
          'prescription_not_found',
        ];
      case 'validation':
        return [
          'missing_consent',
          'incomplete_demographics',
          'invalid_contact_info',
        ];
      case 'boundary':
        return ['max_appointments_per_day', 'max_refills_per_year'];
      case 'security':
        return ['unauthorized_data_access', 'session_timeout_medical'];
      default:
        return ['med_${category}_generic'];
    }
  }

  static List<String> _telehealthOutcomes(String category) {
    switch (category) {
      case 'positive':
        return ['start_consultation', 'join_consultation', 'end_consultation'];
      case 'negative':
        return [
          'provider_unavailable',
          'patient_no_show',
          'network_failure',
          'invalid_meeting_id',
        ];
      case 'validation':
        return ['missing_camera_permission', 'missing_mic_permission'];
      case 'boundary':
        return ['max_participants', 'consultation_duration_limit'];
      case 'security':
        return ['unauthorized_meeting_access', 'eavesdropping_attempt'];
      default:
        return ['telehealth_${category}_generic'];
    }
  }

  static List<String> _defaultOutcomes(String category) {
    return ['generic_$category'];
  }

  static String describeOutcome(String outcome) {
    // Map new outcomes to readable descriptions
    final map = {
      // E‑commerce
      'add_to_cart': 'add item to cart',
      'remove_from_cart': 'remove item from cart',
      'update_quantity': 'update item quantity',
      'apply_coupon': 'apply valid coupon',
      'apply_gift_card': 'apply gift card',
      'invalid_coupon': 'invalid coupon',
      'expired_coupon': 'expired coupon',
      'insufficient_stock': 'out of stock',
      'payment_declined': 'payment declined',
      'invalid_address': 'invalid shipping address',
      'shipping_error': 'shipping method error',
      'empty_cart': 'empty cart',
      'missing_payment_info': 'missing payment info',
      'invalid_quantity': 'invalid quantity',
      'max_items_exceeded': 'max items exceeded',
      'max_quantity_per_item': 'max quantity per item',
      'price_tampering': 'price tampering',
      'quantity_overflow': 'quantity overflow',
      // Banking
      'view_balance': 'view account balance',
      'add_payee': 'add new payee',
      'delete_payee': 'delete payee',
      'schedule_payment': 'schedule future payment',
      'invalid_payee': 'invalid payee account',
      'transfer_limits_exceeded': 'transfer limit exceeded',
      'daily_limit_hit': 'daily transfer limit reached',
      'duplicate_transaction': 'duplicate transaction',
      'empty_amount': 'empty transfer amount',
      'negative_amount': 'negative transfer amount',
      'invalid_account_format': 'invalid account format',
      'min_amount_transfer': 'minimum transfer amount',
      'max_amount_transfer': 'maximum transfer amount',
      // Medical
      'schedule_appointment': 'schedule appointment',
      'cancel_appointment': 'cancel appointment',
      'reschedule_appointment': 'reschedule appointment',
      'prescription_refill_request': 'prescription refill request',
      'view_lab_results': 'view lab results',
      'invalid_insurance': 'invalid insurance',
      'duplicate_booking': 'duplicate appointment booking',
      'refill_too_early': 'refill requested too early',
      'prescription_not_found': 'prescription not found',
      'missing_consent': 'missing patient consent',
      'incomplete_demographics': 'incomplete demographics',
      'invalid_contact_info': 'invalid contact information',
      'max_appointments_per_day': 'max appointments per day',
      'max_refills_per_year': 'max refills per year',
      'unauthorized_data_access': 'unauthorized data access',
      'session_timeout_medical': 'session timeout',
      // Telehealth
      'start_consultation': 'start consultation',
      'join_consultation': 'join consultation',
      'end_consultation': 'end consultation',
      'patient_no_show': 'patient no‑show',
      'network_failure': 'network failure',
      'invalid_meeting_id': 'invalid meeting ID',
      'missing_camera_permission': 'missing camera permission',
      'missing_mic_permission': 'missing microphone permission',
      'max_participants': 'max participants exceeded',
      'consultation_duration_limit': 'consultation duration limit',
      'unauthorized_meeting_access': 'unauthorized meeting access',
      'eavesdropping_attempt': 'eavesdropping attempt',
    };
    if (map.containsKey(outcome)) return map[outcome]!;
    // Fallback for generic outcomes
    if (outcome.startsWith('generic_')) {
      final category = outcome.replaceFirst('generic_', '');
      switch (category) {
        case 'positive':
          return 'successful operation';
        case 'negative':
          return 'operation failure';
        case 'validation':
          return 'input validation';
        case 'boundary':
          return 'boundary condition';
        default:
          return category;
      }
    }
    return outcome.replaceAll('_', ' ');
  }
}
