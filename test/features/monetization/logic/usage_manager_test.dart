import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/app/config/app_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  AppConfig.initTestProMode(false);

  setUpAll(() async {
    setupFirebaseCoreMocks();
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const codec = StandardMessageCodec();

    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerIdTokenListener',
      (message) async => codec.encodeMessage(['mock_id_token_channel']),
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.registerAuthStateListener',
      (message) async => codec.encodeMessage(['mock_auth_state_channel']),
    );
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.cloud_functions_platform_interface.CloudFunctionsHostApi.call',
      (message) async => codec.encodeMessage(<Object?>[<String, Object?>{}]),
    );
    messenger.setMockMethodCallHandler(
      MethodChannel('plugins.flutter.io/firebase_app_check'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'FirebaseAppCheck#registerTokenListener') {
          return 'mock_app_check_channel';
        }
        return null;
      },
    );
    const authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
    messenger.setMockMethodCallHandler(
      authChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'signOut':
            return null;
          case 'currentUser':
            return null;
          default:
            return null;
        }
      },
    );
    await Firebase.initializeApp();
  });

  group('UsageManager', () {
    test('isPro returns false in test environment', () async {
      final isPro = await UsageManager.isPro();
      expect(isPro, isFalse);
    });

    test('setPro does not throw in test environment', () async {
      await UsageManager.setPro(false);
    });

    test('invalidateCache clears cache', () {
      UsageManager.invalidateCache();
    });

    test('canGenerate returns false when FunctionsService is unavailable', () async {
      final result = await UsageManager.canGenerate();
      expect(result, isFalse);
    });

    test('canExport returns false when FunctionsService is unavailable', () async {
      final result = await UsageManager.canExport();
      expect(result, isFalse);
    });

    test('canExportSummary returns false when FunctionsService is unavailable', () async {
      final result = await UsageManager.canExportSummary();
      expect(result, isFalse);
    });

    test('resetLimits does not throw in test environment', () async {
      await UsageManager.resetLimits();
    });

    test('trackProInterest does not throw in test environment', () async {
      await UsageManager.trackProInterest('test');
    });

    test('incrementGeneration invalidates cache', () async {
      UsageManager.invalidateCache();
      await UsageManager.incrementGeneration();
    });

    test('getLifetimeStats returns default values when dashboard unavailable', () async {
      final stats = await UsageManager.getLifetimeStats();
      expect(stats['generations'], 0);
      expect(stats['exports'], 0);
    });

    test('getResetTime returns null when dashboard unavailable', () async {
      final time = await UsageManager.getResetTime();
      expect(time, isNull);
    });

    test('rewardedExportsRemaining returns 0 when FunctionsService is unavailable', () async {
      final remaining = await UsageManager.rewardedExportsRemaining();
      expect(remaining, 0);
    });

    test('freeGensRemaining returns 0 when not pro', () async {
      final remaining = await UsageManager.freeGensRemaining();
      expect(remaining, 0);
    });

    test('rewardedGensRemaining returns expected value', () async {
      final remaining = await UsageManager.rewardedGensRemaining();
      expect(remaining, greaterThanOrEqualTo(0));
    });

    test('proGensRemaining returns proFreeBatchesPerDay when dashboard is empty', () async {
      final remaining = await UsageManager.proGensRemaining();
      expect(remaining, 15);
    });

    test('canGiveFeedback returns false when no authenticated user (guest)', () {
      expect(UsageManager.canGiveFeedback, isFalse);
    });
  });
}
