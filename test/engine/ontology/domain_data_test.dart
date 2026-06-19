import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/domain_data.dart';

void main() {
  group('DomainData', () {
    test('samples contains all expected domains', () {
      expect(DomainData.samples.containsKey('Identity'), isTrue);
      expect(DomainData.samples.containsKey('Commerce'), isTrue);
      expect(DomainData.samples.containsKey('Transaction'), isTrue);
      expect(DomainData.samples.containsKey('Scheduling'), isTrue);
      expect(DomainData.samples.containsKey('Records'), isTrue);
      expect(DomainData.samples.containsKey('Integration'), isTrue);
    });

    test('Identity domain has expected sample steps', () {
      final identity = DomainData.samples['Identity']!;
      expect(identity.containsKey('TapLoginField'), isTrue);
      expect(identity.containsKey('EnterCredentials'), isTrue);
      expect(identity.containsKey('TapSubmit'), isTrue);
      expect(identity.containsKey('VerifyDashboard'), isTrue);
      expect(identity.containsKey('ClickLoginButton'), isTrue);
      expect(identity.containsKey('EnterEmailAndPassword'), isTrue);
      expect(identity.containsKey('ClickSubmit'), isTrue);
      expect(identity.containsKey('VerifyLandingPage'), isTrue);
      expect(identity.containsKey('PostAuthPayload'), isTrue);
      expect(identity.containsKey('ReceiveToken'), isTrue);
      expect(identity.containsKey('VerifyStatusCode200'), isTrue);
      expect(identity.containsKey('TapForgotPassword'), isTrue);
      expect(identity.containsKey('EnterEmail'), isTrue);
      expect(identity.containsKey('VerifyEmailSent'), isTrue);
      expect(identity.containsKey('ClickResetLink'), isTrue);
      expect(identity.containsKey('EnterNewPassword'), isTrue);
      expect(identity.containsKey('ClickConfirm'), isTrue);
      expect(identity.containsKey('VerifySuccessToast'), isTrue);
    });

    test('all sample values are non-empty strings', () {
      for (final domain in DomainData.samples.values) {
        for (final value in domain.values) {
          expect(value, isNotEmpty);
        }
      }
    });

    test('Commerce domain has expected steps', () {
      final commerce = DomainData.samples['Commerce']!;
      expect(commerce['BrowseCatalog'], contains('product listings'));
      expect(commerce['TapAddToCart'], contains('Add to Cart'));
      expect(commerce['ProceedToCheckout'], contains('Proceed to Checkout'));
    });

    test('Transaction domain has expected steps', () {
      final transaction = DomainData.samples['Transaction']!;
      expect(transaction['TapTransferMenu'], contains('Transfer'));
      expect(transaction['PostTransferPayload'], contains('POST /transfer'));
    });

    test('Scheduling domain has expected steps', () {
      final scheduling = DomainData.samples['Scheduling']!;
      expect(scheduling['NavigateToDateRange'], contains('2026'));
      expect(scheduling['VerifyApprovalStatus'], contains('Pending Approval'));
    });

    test('Records domain has expected steps', () {
      final records = DomainData.samples['Records']!;
      expect(records['NavigateToRecords'], contains('Records section'));
      expect(records['OpenPDFDocument'], contains('PDF'));
    });

    test('Integration domain has expected steps', () {
      final integration = DomainData.samples['Integration']!;
      expect(integration['ClickTriggerPipeline'], contains('POST /pipeline/trigger'));
      expect(integration['VerifyDeploymentSuccess'], contains('build.status'));
    });
  });
}
