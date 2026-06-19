import 'package:flutter_test/flutter_test.dart';
import 'package:qa_genie/engine/ontology/entities.dart';

void main() {
  group('EntityType', () {
    test('all enum values have a displayName', () {
      for (final entity in EntityType.values) {
        expect(entity.displayName, isNotEmpty);
      }
    });

    test('displayName returns correct name for each entity', () {
      expect(EntityType.account.displayName, 'account');
      expect(EntityType.credential.displayName, 'credential');
      expect(EntityType.otp.displayName, 'OTP');
      expect(EntityType.mfa.displayName, 'MFA');
      expect(EntityType.oauthProvider.displayName, 'OAuth provider');
      expect(EntityType.roleAssignment.displayName, 'role assignment');
      expect(EntityType.permissionSet.displayName, 'permission set');
      expect(EntityType.loginAttempt.displayName, 'login attempt');
      expect(EntityType.resetToken.displayName, 'reset token');
      expect(EntityType.giftCard.displayName, 'gift card');
      expect(EntityType.shippingMethod.displayName, 'shipping method');
      expect(EntityType.accountTx.displayName, 'account');
      expect(EntityType.meetingLink.displayName, 'meeting link');
      expect(EntityType.labResult.displayName, 'lab result');
      expect(EntityType.insuranceRecord.displayName, 'insurance record');
      expect(EntityType.apiKey.displayName, 'API key');
      expect(EntityType.rateLimit.displayName, 'rate limit');
      expect(EntityType.result.displayName, 'result');
      expect(EntityType.payload.displayName, 'payload');
    });

    test('enum values are not empty', () {
      expect(EntityType.values.length, greaterThan(0));
    });
  });
}
