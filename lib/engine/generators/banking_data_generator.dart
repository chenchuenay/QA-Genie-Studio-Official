import 'dart:math';
import 'package:qa_genie/engine/generators/data_generator.dart';


class BankingDataGenerator implements DataGenerator {
  @override
  Map<String, dynamic> generate({
    required String outcome,
    required String seed,
  }) {
    final random = Random(seed.hashCode);
    switch (outcome) {
      case 'view_balance':
        return {'account_id': 'acc_${random.nextInt(10000)}'};
      case 'add_payee':
        return {
          'payee_name': 'Payee ${random.nextInt(1000)}',
          'payee_account': 'ACC${random.nextInt(100000)}',
        };
      case 'delete_payee':
        return {'payee_id': 'pay_${random.nextInt(1000)}'};
      case 'valid_transfer':
        return {
          'from_account': 'acc_${random.nextInt(10000)}',
          'to_account': 'acc_${random.nextInt(10000)}',
          'amount': (random.nextInt(5000) + 1).toString(),
        };
      case 'schedule_payment':
        return {
          'payee_id': 'pay_${random.nextInt(1000)}',
          'amount': (random.nextInt(2000) + 1).toString(),
          'date': '2025-${random.nextInt(12) + 1}-${random.nextInt(28) + 1}',
        };
      case 'insufficient_funds':
        return {
          'from_account': 'acc_${random.nextInt(10000)}',
          'amount': (random.nextInt(50000) + 10000).toString(),
        };
      case 'invalid_payee':
        return {'payee_account': 'INVALID_ACCOUNT'};
      case 'transfer_limits_exceeded':
        return {'amount': '15001', 'daily_limit': '15000'};
      case 'daily_limit_hit':
        return {'amount': '5000', 'daily_remaining': '0'};
      case 'duplicate_transaction':
        return {'transaction_id': 'tx_${random.nextInt(10000)}'};
      case 'min_amount_transfer':
        return {'amount': '0.01'};
      case 'max_amount_transfer':
        return {'amount': '10000'};
      default:
        return {};
    }
  }
}
