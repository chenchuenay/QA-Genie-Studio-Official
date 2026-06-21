import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;
  static bool get isGuest {
    try {
      final user = _auth.currentUser;
      if (user == null) return true;
      // Linked with Google → user account, not guest
      for (final info in user.providerData) {
        if (info.providerId == 'google.com') return false;
      }
      return user.uid.startsWith('guest_');
    } catch (_) {
      return true; // Firebase not initialized — safe default
    }
  }

  // "Continue as guest" – uses custom token (persistent per device)
  static Future<UserCredential> signInAsGuest({bool forceReturning = false}) async {
    debugPrint('🔐 AuthService: signInAsGuest start');
    try {
      final deviceId = await DeviceUtils.getUniqueId();
      final token = await FunctionsService.getGuestToken(deviceId: deviceId, forceReturning: forceReturning);
      final credential = await _auth.signInWithCustomToken(token);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_returning_guest', forceReturning);
      debugPrint('✅ Signed in as guest: ${credential.user?.uid}');
      return credential;
    } catch (e) {
      debugPrint('❌ Guest sign-in failed: $e');
      rethrow;
    }
  }

  // Link existing guest to Google account (upgrade)
  static Future<UserCredential> linkWithGoogle() async {
    debugPrint('🔐 AuthService: linkWithGoogle start');
    try {
      // Check email cooldown before proceeding with Google sign-in
      final googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount == null) throw Exception('Google sign-in cancelled');
      
      try {
        await FunctionsService.call(
          functionName: 'checkEmailCooldown',
          payload: {'email': googleSignInAccount.email},
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('cooldown') || msg.contains('permission-denied')) {
          throw FirebaseAuthException(
            code: 'permission-denied',
            message: 'This Google account was recently deleted and cannot be used again for 24 hours.',
          );
        }
        // Don't block on other errors — proceed
      }

      // Attempt to ensure a guest user exists first, but don't fail if guest creation fails
      if (_auth.currentUser == null) {
        try {
          await signInAsGuest();
        } catch (e) {
          debugPrint(
            '⚠️ AuthService: Guest sign-in failed during link preparation: $e',
          );
        }
      }

      final googleUser = googleSignInAccount;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final User? current = _auth.currentUser;
      UserCredential result;

      if (current != null) {
        try {
          result = await current.linkWithCredential(credential);
          debugPrint(
            '✅ Linked guest to Google, UID remains: ${result.user?.uid}',
          );
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' ||
              e.code == 'provider-already-linked') {
            debugPrint(
              '🔄 Credential in use or already linked, switching accounts',
            );
            result = await _auth.signInWithCredential(credential);
          } else {
            rethrow;
          }
        }
      } else {
        debugPrint('🔄 No current user, performing direct Google sign-in');
        result = await _auth.signInWithCredential(credential);
      }

      final user = result.user!;
      final deviceId = await DeviceUtils.getUniqueId();

      // Attempt to sync with backend, but don't block the UI on it
      unawaited(
        FunctionsService.linkGoogleAccount(
          email: user.email ?? googleUser.email,
          displayName: user.displayName ?? googleUser.displayName ?? '',
          deviceId: deviceId,
        ).catchError(
          (e) => debugPrint('⚠️ linkGoogleAccount backend sync failed: $e'),
        ),
      );

      debugPrint('✅ Google account process completed');
      return result;
    } catch (e) {
      debugPrint('❌ linkWithGoogle failed: $e');
      throw Exception('Authentication failed: $e');
    }
  }

  // Sign out and return to guest state
  static Future<void> signOut() async {
    debugPrint('🔐 AuthService: signOut');
    try {
      await _googleSignIn.signOut();
    } catch (e, _) {
      debugPrint('🔐 AuthService: Google sign-out error: $e');
    }
    try {
      await _auth.signOut();
    } catch (e, _) {
      debugPrint('🔐 AuthService: Firebase sign-out error: $e');
    }
    // Clear local guest cache
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_display_name');
      await prefs.remove('stats_generations');
      await prefs.remove('stats_exports');
      await prefs.remove('stats_last_sync');
      await prefs.remove('is_pro');
    } catch (e, _) {
      debugPrint('🔐 AuthService: cache clear error: $e');
    }
    try {
      await signInAsGuest(forceReturning: true);
    } catch (e, _) {
      debugPrint('🔐 AuthService: Guest sign-in error: $e');
    }
    // Re-initialize database under device-level identity (data persists across auth changes)
    try {
      final deviceId = await DeviceUtils.getUniqueId();
      await _reinitializeDb(deviceId);
    } catch (e, _) {
      debugPrint('🔐 AuthService: DB re-init error: $e');
    }
  }

  static Future<void> _reinitializeDb(String identity) async {
    await DatabaseService.initDatabase(identity);
    DatabaseService.invalidateSuitesCache();
  }
}
