import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';

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
    messenger.setMockMessageHandler(
      'dev.flutter.pigeon.firebase_auth_platform_interface.FirebaseAuthHostApi.signOut',
      (message) async => codec.encodeMessage(<Object?>[]),
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
    messenger.setMockMethodCallHandler(
      MethodChannel('plugins.flutter.io/google_sign_in'),
      (MethodCall methodCall) async => null,
    );
    messenger.setMockMethodCallHandler(
      MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationSupportDirectory') {
          return Directory.systemTemp.path;
        }
        return Directory.systemTemp.path;
      },
    );

    const authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
    messenger.setMockMethodCallHandler(
      authChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'signOut':
            return null;
          case 'signInWithCustomToken':
            return {'uid': 'guest_test_uid', 'isAnonymous': true};
          case 'currentUser':
            return null;
          default:
            return null;
        }
      },
    );
    await Firebase.initializeApp();
  });

  group('AuthService', () {
    test('authStateChanges returns a non-null stream', () {
      expect(AuthService.authStateChanges, isNotNull);
    });

    test('currentMember is null in test environment', () {
      expect(AuthService.currentMember, isNull);
    });

    test('isAnonymous returns false when currentUser is null', () {
      expect(AuthService.isAnonymous, isFalse);
    });

    test('isGuest returns true when currentUser is null', () {
      expect(AuthService.isGuest, isTrue);
    });

    test('signOut handles null user gracefully', () async {
      await AuthService.signOut();
    });

    test('signInAsGuest throws when Firebase auth channel fails', () async {
      expect(
        () => AuthService.signInAsGuest(),
        throwsA(isA<Exception>()),
      );
    });

    test('linkWithGoogle throws when Google sign-in fails', () async {
      expect(
        () => AuthService.linkWithGoogle(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
