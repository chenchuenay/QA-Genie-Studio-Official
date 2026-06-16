import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  // "Continue as guest" – uses custom token (persistent per device)
  static Future<UserCredential> signInAsGuest() async {
    debugPrint('🔐 AuthService: signInAsGuest start');
    final deviceId = await DeviceUtils.getUniqueId();
    final token = await FunctionsService.getGuestToken(deviceId: deviceId);
    final credential = await _auth.signInWithCustomToken(token);
    debugPrint('✅ Signed in as guest: ${credential.user?.uid}');
    return credential;
  }

  // Link existing guest to Google account (upgrade)
  static Future<UserCredential> linkWithGoogle() async {
    debugPrint('🔐 AuthService: linkWithGoogle start');
    try {
      // Attempt to ensure a guest user exists first, but don't fail if guest creation fails
      if (_auth.currentUser == null) {
        try {
          await signInAsGuest();
        } catch (e) {
          debugPrint('⚠️ AuthService: Guest sign-in failed during link preparation: $e');
          // We will proceed with a direct sign-in instead of a link if no user is present
        }
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('Google sign-in cancelled');

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
          debugPrint('✅ Linked guest to Google, UID remains: ${result.user?.uid}');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'credential-already-in-use' || e.code == 'provider-already-linked') {
            debugPrint('🔄 Credential in use or already linked, switching accounts');
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
      unawaited(FunctionsService.linkGoogleAccount(
        email: user.email ?? googleUser.email,
        displayName: user.displayName ?? googleUser.displayName ?? '',
        deviceId: deviceId,
      ).catchError((e) => debugPrint('⚠️ linkGoogleAccount backend sync failed: $e')));

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
    await _googleSignIn.signOut();
    await _auth.signOut();
    await signInAsGuest();
  }

  // Legacy anonymous sign‑in (kept for compatibility)
  static Future<UserCredential> signInAnonymously() async {
    debugPrint('🔐 AuthService: signInAnonymously (legacy)');
    final cred = await _auth.signInAnonymously();
    try {
      await FunctionsService.call(functionName: 'getGuestName');
    } catch (_) {}
    return cred;
  }
}
