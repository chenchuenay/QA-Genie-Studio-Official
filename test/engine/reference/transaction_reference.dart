import 'identity_reference.dart';

class TransactionReference {
  static final cases = [
    ReferenceCase(
      title: 'User transfers funds to a valid beneficiary with sufficient balance',
      type: 'POSITIVE',
      priority: 'High',
      preconditions: [
        'User is authenticated with an active banking session',
        'Source account (Savings XXXX-8901) has sufficient balance (\$5,000+)',
        'Beneficiary (John Doe XXXX-4567) is added and verified',
        'Daily transfer limit has not been reached (\$10,000 limit, \$0 used today)',
        'Two-factor authentication (OTP) is available on the registered device',
      ],
      testData:
          'fromAccount=Savings XXXX-8901, toAccount=John Doe XXXX-4567, amount=\$250.00, otp=123456, platform=Mobile',
      steps: [
        'Open the mobile banking app and navigate to "Transfer" section',
        'Select source account: Savings (XXXX-8901) — balance shows \$5,000+',
        'Select recipient: John Doe (XXXX-4567) from the beneficiary list',
        'Enter transfer amount: \$250.00',
        'Enter transaction note: "Payment for invoice INV-2026-0619"',
        'Tap "Continue" and verify transfer summary details',
        'Enter OTP: 123456 received via SMS/authenticator app',
        'Tap "Confirm Transfer" to execute the transaction',
        'Verify success screen shows transaction ID: TXN-2026-0619-8842',
      ],
      expectedResult:
          'The transfer is executed successfully. A confirmation screen displays the transaction details: amount \$250.00, from Savings XXXX-8901, to John Doe XXXX-4567, with a unique transaction ID (TXN-2026-0619-8842). The source account balance decreases by \$250.00. The beneficiary receives the funds. A transaction receipt is generated.',
    ),
    ReferenceCase(
      title: 'Transfer attempt with insufficient balance shows insufficient funds error',
      type: 'NEGATIVE',
      priority: 'High',
      preconditions: [
        'User is authenticated with an active banking session',
        'Source account (Checking XXXX-5678) has balance of \$50.00',
        'Transfer amount (\$500.00) exceeds available balance',
        'No overdraft protection is enabled on the account',
        'Beneficiary is valid and verified',
      ],
      testData:
          'fromAccount=Checking XXXX-5678, toAccount=Jane Smith XXXX-9012, amount=\$500.00, balance=\$50.00, platform=Web',
      steps: [
        'Navigate to the Funds Transfer page in online banking',
        'Select source account: Checking (XXXX-5678) — balance displays \$50.00',
        'Select recipient: Jane Smith (XXXX-9012)',
        'Enter amount: \$500.00',
        'Click "Review Transfer" to proceed',
        'Observe the error response before OTP step',
      ],
      expectedResult:
          'The transfer is rejected before reaching the OTP confirmation step. An inline error displays: "Insufficient funds. Your available balance is \$50.00. Please enter a lower amount." No holds are placed on the account. No OTP is sent. The transfer is not recorded in the transaction history.',
    ),
    ReferenceCase(
      title: 'Authorization hold placed on payment card is released after refund processing',
      type: 'POSITIVE',
      priority: 'Medium',
      preconditions: [
        'A prior authorization hold of \$150.00 exists on card VISA-4242',
        'The merchant initiates a full refund for the original transaction',
        'Refund amount does not exceed the original authorization amount',
        'Card is still active and not expired',
      ],
      testData:
          'originalTxnId=TXN-2026-0615-001, refundAmount=\$150.00, card=VISA-4242, reason=Customer returned item, platform=API',
      steps: [
        'Send POST /api/v1/refunds with original transaction ID and refund amount',
        'Include refund reason: "Customer returned item — order ORD-2026-0615-003"',
        'Verify API response returns HTTP 200 with refund confirmation',
        'Check the card statement/transaction log for the refund entry',
        'Verify the authorization hold (\$150.00) is released and available balance increases',
      ],
      expectedResult:
          'The refund is processed successfully. The API returns HTTP 200 with refund ID: RFD-2026-0619-003. The authorization hold of \$150.00 on VISA-4242 is released. The available credit increases by \$150.00. The refund appears in the transaction history with status "Completed." The original transaction status updates to "Refunded."',
    ),
  ];
}
