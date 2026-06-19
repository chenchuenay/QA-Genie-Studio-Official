import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/planners/domain_detector.dart';
import 'package:qa_genie/engine/domains/scheduling_domain.dart';
import 'package:qa_genie/engine/domains/identity_domain.dart';
import 'package:qa_genie/engine/domains/commerce_domain.dart';
import 'package:qa_genie/engine/domains/transaction_domain.dart';
import 'package:qa_genie/engine/domains/records_domain.dart';
import 'package:qa_genie/engine/domains/integration_domain.dart';

void main() {
  group('DomainDetector', () {
    group('detect Scheduling domain', () {
      test('detects from appointment keyword', () {
        final ctx = DomainDetector.detect('Scheduling', 'Appointment Booking');
        expect(ctx.id, SchedulingDomain.context.id);
      });

      test('detects from schedule keyword', () {
        final ctx = DomainDetector.detect('Calendar', 'Schedule');
        expect(ctx.id, SchedulingDomain.context.id);
      });

      test('detects from provider keyword', () {
        final ctx = DomainDetector.detect('Health', 'Provider Management');
        expect(ctx.id, SchedulingDomain.context.id);
      });
    });

    group('detect Identity domain', () {
      test('detects from login keyword', () {
        final ctx = DomainDetector.detect('Auth', 'Login');
        expect(ctx.id, IdentityDomain.context.id);
      });

      test('detects from signin keyword', () {
        final ctx = DomainDetector.detect('User', 'SignIn');
        expect(ctx.id, IdentityDomain.context.id);
      });

      test('detects from authentication keyword', () {
        final ctx = DomainDetector.detect('Security', 'Authenticate User');
        expect(ctx.id, IdentityDomain.context.id);
      });

      test('detects from password keyword', () {
        final ctx = DomainDetector.detect('Account', 'Password Reset');
        expect(ctx.id, IdentityDomain.context.id);
      });

      test('detects from session keyword', () {
        final ctx = DomainDetector.detect('System', 'Session Management');
        expect(ctx.id, IdentityDomain.context.id);
      });
    });

    group('detect Commerce domain', () {
      test('detects from cart keyword', () {
        final ctx = DomainDetector.detect('Shopping', 'Cart');
        expect(ctx.id, CommerceDomain.context.id);
      });

      test('detects from checkout keyword', () => expect(DomainDetector.detect('Store', 'Checkout').id, CommerceDomain.context.id));

      test('detects from coupon keyword', () => expect(DomainDetector.detect('Promo', 'Coupon Apply').id, CommerceDomain.context.id));

      test('detects from payment keyword', () => expect(DomainDetector.detect('Billing', 'Payment').id, CommerceDomain.context.id));
    });

    group('detect Transaction domain', () {
      test('detects from transfer keyword', () {
        final ctx = DomainDetector.detect('Banking', 'Transfer Funds');
        expect(ctx.id, TransactionDomain.context.id);
      });

      test('detects from wallet keyword', () => expect(DomainDetector.detect('Finance', 'Wallet').id, TransactionDomain.context.id));

      test('detects from deposit keyword', () => expect(DomainDetector.detect('Account', 'Deposit').id, TransactionDomain.context.id));

      test('detects from beneficiary keyword', () {
        expect(DomainDetector.detect('Finance', 'Beneficiary Mgmt').id, TransactionDomain.context.id);
      });
    });

    group('detect Records domain', () {
      test('detects from record keyword', () {
        final ctx = DomainDetector.detect('Health', 'Record Access');
        expect(ctx.id, RecordsDomain.context.id);
      });

      test('detects from prescription keyword', () {
        expect(DomainDetector.detect('Pharmacy', 'Prescription').id, RecordsDomain.context.id);
      });

      test('detects from lab keyword', () => expect(DomainDetector.detect('Lab', 'Results').id, RecordsDomain.context.id));
    });

    group('detect Integration domain', () {
      test('detects from webhook keyword', () {
        final ctx = DomainDetector.detect('API', 'Webhook');
        expect(ctx.id, IntegrationDomain.context.id);
      });

      test('detects from endpoint keyword', () {
        expect(DomainDetector.detect('System', 'Endpoint Config').id, IntegrationDomain.context.id);
      });

      test('detects from integration keyword', () {
        expect(DomainDetector.detect('External', 'Integration').id, IntegrationDomain.context.id);
      });
    });

    group('fallback behavior', () {
      test('returns commerce domain for unrecognized input', () {
        final ctx = DomainDetector.detect('Unknown', 'Miscellaneous Feature');
        expect(ctx.id, CommerceDomain.context.id);
      });

      test('returns commerce domain for empty strings', () {
        final ctx = DomainDetector.detect('', '');
        expect(ctx.id, CommerceDomain.context.id);
      });
    });

    group('keyword matching precedence', () {
      test('scheduling takes precedence over commerce for appointment keyword', () {
        final ctx = DomainDetector.detect('Store', 'Appointment Booking');
        expect(ctx.id, SchedulingDomain.context.id);
      });

      test('identity takes precedence over fallback', () {
        final ctx = DomainDetector.detect('Anything', 'Login Feature');
        expect(ctx.id, IdentityDomain.context.id);
      });
    });

    group('_containsAny', () {
      test('returns true when text contains any keyword', () {
        expect(DomainDetector.detect('login_test', 'feature').id, IdentityDomain.context.id);
      });

      test('matches case-insensitively', () {
        expect(DomainDetector.detect('LOGIN', 'FEATURE').id, IdentityDomain.context.id);
      });
    });
  });
}
