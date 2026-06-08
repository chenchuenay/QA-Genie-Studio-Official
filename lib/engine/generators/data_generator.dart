import '../models/scenario.dart';
import '../ontology/actions.dart';
import '../ontology/entities.dart';
import '../../core/utils/test_data_factory.dart';

class DataGenerator {
  static Map<String, String> generate(Scenario scenario, String constraints) {
    final data = <String, String>{};
    final action = scenario.action;
    final entity = scenario.entity;

    if (action == ActionType.login || action == ActionType.authenticate) {
      data['email'] = TestDataFactory.validEmail();
      data['password'] = TestDataFactory.validPassword();
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
    } else if (action == ActionType.create &&
        entity == EntityType.appointment) {
      data['slot'] = 'slot_available';
    }

    final lower = constraints.toLowerCase();
    if (lower.contains('sql'))
      data['sql_payload'] = TestDataFactory.sqlInjection();
    if (lower.contains('xss'))
      data['xss_payload'] = TestDataFactory.xssPayload();

    if (data.isEmpty) {
      data['entity_id'] = 'TEST_${entity.name.toUpperCase()}_001';
    }
    return data;
  }
}
