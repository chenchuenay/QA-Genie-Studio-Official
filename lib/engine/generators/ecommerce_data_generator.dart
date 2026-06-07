import 'dart:math';
import 'package:qa_genie/engine/generators/data_generator.dart';


class EcommerceDataGenerator implements DataGenerator {
  @override
  Map<String, dynamic> generate({
    required String outcome,
    required String seed,
  }) {
    final random = Random(seed.hashCode);
    switch (outcome) {
      case 'add_to_cart':
        return {
          'product_id': 'prod_${random.nextInt(1000)}',
          'quantity': random.nextInt(5) + 1,
        };
      case 'remove_from_cart':
        return {'product_id': 'prod_${random.nextInt(1000)}'};
      case 'update_quantity':
        return {
          'product_id': 'prod_${random.nextInt(1000)}',
          'new_quantity': random.nextInt(5) + 1,
        };
      case 'apply_coupon':
        return {'coupon_code': 'SAVE${random.nextInt(30) + 10}'};
      case 'apply_gift_card':
        return {'gift_card_code': 'GIFT${random.nextInt(10000)}'};
      case 'valid_checkout':
        return {'payment_method': 'credit_card'};
      case 'invalid_coupon':
        return {'coupon_code': 'INVALID_COUPON'};
      case 'expired_coupon':
        return {'coupon_code': 'EXPIRED_CODE'};
      case 'insufficient_stock':
        return {'product_id': 'prod_outofstock', 'requested_quantity': 10};
      case 'payment_declined':
        return {'card_last4': '1111', 'decline_reason': 'insufficient_funds'};
      case 'max_items_exceeded':
        return {'cart_limit': 100, 'attempted_items': 101};
      case 'max_quantity_per_item':
        return {'max_quantity': 5, 'attempted_quantity': 6};
      default:
        return {};
    }
  }
}
