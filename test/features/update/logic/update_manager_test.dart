import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/features/update/logic/update_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
    const packageChannel = MethodChannel('dev.fluttercommunity.plus/package_info');
    messenger.setMockMethodCallHandler(
      packageChannel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'getAll') {
          return {
            'app_name': 'QAG Studio',
            'package_name': 'com.enaykumar.qagenie',
            'version': '1.2.305',
            'build_number': '305',
          };
        }
        return null;
      },
    );
    const firestoreChannel = MethodChannel('plugins.flutter.io/firebase_firestore');
    messenger.setMockMethodCallHandler(
      firestoreChannel,
      (MethodCall methodCall) async {
        return null;
      },
    );
    await Firebase.initializeApp();
  });

  group('UpdateManager.noUpdate', () {
    test('returns an UpdateCheckResult with updateRequired = false', () {
      final result = UpdateManager.noUpdate();
      expect(result.updateRequired, false);
      expect(result.latestVersion, '');
      expect(result.latestBuild, '');
      expect(result.blockBelowBuild, '');
      expect(result.updateUrl, '');
      expect(result.dismissCount, 0);
      expect(result.blocked, false);
    });
  });

  group('UpdateManager.checkForUpdate', () {
    test('returns noUpdate when Firebase is not configured', () async {
      final result = await UpdateManager.checkForUpdate();
      expect(result.updateRequired, false);
    });
  });

  group('UpdateManager.recordDismissal', () {
    test('does not throw in test environment', () async {
      await UpdateManager.recordDismissal();
    });
  });
}
