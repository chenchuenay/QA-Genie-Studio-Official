import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Link Google account to existing anonymous user.
  /// If no anonymous user exists, it will create one.
  static Future<UserCredential> linkWithGoogle() async {
    try {
      // Ensure an anonymous user exists
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
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
      if (current == null) throw Exception('No authenticated user');

      try {
        final UserCredential result = await current.linkWithCredential(
          credential,
        );
        await _updateUserDocumentWithRetry(result.user!);
        return result;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use') {
          // If already linked to another account, sign in with that one instead
          debugPrint('AuthService: Credential in use, switching accounts');
          final result = await _auth.signInWithCredential(credential);
          await _updateUserDocumentWithRetry(result.user!);
          return result;
        }
        rethrow;
      }
    } catch (e) {
      throw Exception('Authentication failed: $e');
    }
  }

  static Future<void> _updateUserDocumentWithRetry(
    User user, {
    int maxRetries = 3,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await _updateUserDocument(user);
        return;
      } catch (e) {
        if (i == maxRetries - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
      }
    }
  }

  static Future<void> _updateUserDocument(User user) async {
    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);
    final doc = await userRef.get();
    final now = FieldValue.serverTimestamp();

    if (!doc.exists) {
      await userRef.set({
        'uid': user.uid,
        'provider': 'google',
        'isGuest': false,
        'createdAt': now,
        'lastLoginAt': now,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'accountType': 'google',
        'linkedAt': now,
      });
    } else {
      await userRef.update({
        'provider': 'google',
        'isGuest': false,
        'lastLoginAt': now,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoURL,
        'accountType': 'google',
        'linkedAt': now,
      });
    }
  }

  static Future<User> ensureAnonymous() async {
    User? user = _auth.currentUser;
    if (user == null) {
      final cred = await _auth.signInAnonymously();
      user = cred.user;
    } else if (!user.isAnonymous) {
      return user;
    }
    return user!;
  }
}
