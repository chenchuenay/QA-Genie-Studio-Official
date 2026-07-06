import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/core/cloud/cloud_sync_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qa_genie/firebase/analytics/analytics_service.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/features/auth/services/session_monitor.dart';

class CredentialAlreadyInUseException implements Exception {
  final GoogleSignInAuthentication googleAuth;
  final GoogleSignInAccount googleAccount;
  final String? previousGuestUid;
  CredentialAlreadyInUseException({
    required this.googleAuth,
    required this.googleAccount,
    this.previousGuestUid,
  });
}

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.isDev
        ? '113750340081-c093td8t5790acqpii0o40fqk2susboj.apps.googleusercontent.com'
        : '88626021268-f0u2amqbp3s6ih2hl83c1p7iv60p7lt6.apps.googleusercontent.com',
  );
  static bool _googleAuthInProgress = false;
  static bool get isGoogleAuthInProgress => _googleAuthInProgress;

  static Future<void> _writeLog(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/auth_debug.log');
      await file.writeAsString(
        '${DateTime.now().toIso8601String()} | $message\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  }

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentMember => _auth.currentUser;
  static bool get isMember => currentMember != null && !isGuest;
  static bool get isAnonymous => currentMember?.isAnonymous ?? false;
  static bool get isGuest {
    try {
      final member = _auth.currentUser;
      if (member == null) return true;
      // Linked with Google → this is a member, not a guest
      for (final info in member.providerData) {
        if (info.providerId == 'google.com') return false;
      }
      return member.uid.startsWith('guest_');
    } catch (_) {
      return true; // Firebase not initialized — safe default
    }
  }

  // "Continue as guest" – uses custom token (persistent per device)
  static Future<UserCredential> signInAsGuest({bool forceReturning = false, String caller = 'signInAsGuest'}) async {
    await _writeLog('signInAsGuest CALLED | caller=$caller | forceReturning=$forceReturning');
    if (_googleAuthInProgress) {
      await _writeLog('BLOCKED: googleAuthInProgress | caller=$caller');
      throw Exception(
        'GUARD_BLOCK: signInAsGuest called while googleAuthInProgress=true | caller=$caller',
      );
    }
    try {
      final everCreated = await DeviceUtils.guestEverCreated();
      if (everCreated && !forceReturning) {
        forceReturning = true;
      }

      final deviceId = await DeviceUtils.getUniqueId();
      await _writeLog('signInAsGuest | deviceId=$deviceId | forceReturning=$forceReturning | everCreated=$everCreated');
      // Get ANDROID_ID for cross-reference (survives data clear)
      String? androidId;
      try {
        final info = await DeviceInfoPlugin().androidInfo;
        androidId = info.id;
      } catch (_) {}
      final tokenResult = await FunctionsService.getGuestToken(
        deviceId: deviceId,
        forceReturning: forceReturning,
        caller: caller,
        androidId: androidId,
      );
      final token = tokenResult['token'] as String;
      final guestTier = tokenResult['guestTier'] as String?;
      await _writeLog('signInAsGuest | got token from cloud function | guestTier=$guestTier');
      debugPrint('🔐 signInAsGuest: about to call signInWithCustomToken | caller=$caller');
      final credential = await _auth.signInWithCustomToken(token);
      debugPrint('🔐 signInAsGuest: signInWithCustomToken SUCCESS | uid=${credential.user?.uid}');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_returning_guest', guestTier == 'returning');

      if (!everCreated) {
        await DeviceUtils.setGuestEverCreated();
      }

      // Invalidate usage cache so next quota fetch reflects correct tier
      UsageManager.invalidateCache();

      await _writeLog('signInAsGuest SUCCESS | uid=${credential.user?.uid}');
      return credential;
    } catch (e) {
      await _writeLog('signInAsGuest FAILED | $e');
      debugPrint('🔐 signInAsGuest FAILED | caller=$caller | error=$e');
      rethrow;
    }
  }

  // Link existing guest to Google account (upgrade)
  // Accept an optional preSignedInAccount to avoid double Google sign-in
  // when the caller already obtained the account for session checking.
  static Future<UserCredential> linkWithGoogle({GoogleSignInAccount? preSignedInAccount, bool isReturningGuest = false}) async {
    _googleAuthInProgress = true;
    await AnalyticsService.logDebug(message: 'linkWithGoogle: ENTER');
    await _writeLog('linkWithGoogle CALLED');
    try {
      final googleSignInAccount = preSignedInAccount ?? await _googleSignIn.signIn();
      if (googleSignInAccount == null) {
        await _writeLog('linkWithGoogle | Google sign-in cancelled');
        throw Exception('Google sign-in cancelled');
      }
      await _writeLog('linkWithGoogle | Google account selected: ${googleSignInAccount.email}');
      // Cooldown check already performed in auth_dialog before this call

      final googleUser = googleSignInAccount;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final User? current = _auth.currentUser;
      final String? previousGuestUid = current != null && current.uid.startsWith('guest_') ? current.uid : null;
      await _writeLog('linkWithGoogle | currentMember=${current?.uid} | previousGuestUid=$previousGuestUid');
      UserCredential result;

      if (current != null) {
        await _writeLog('linkWithGoogle | linking credential to existing member');
        try {
          result = await current.linkWithCredential(credential);
          await _writeLog('linkWithGoogle | linked OK, uid=${result.user?.uid}');
        } on FirebaseAuthException catch (e) {
          await _writeLog('linkWithGoogle | link error: ${e.code}');
          if (e.code == 'credential-already-in-use' ||
              e.code == 'provider-already-linked') {
            if (isReturningGuest) {
              await _writeLog('linkWithGoogle | returning guest — silent signInWithCredential');
              result = await _auth.signInWithCredential(credential);
            } else {
              await _writeLog('linkWithGoogle | first-time guest — throwing CredentialAlreadyInUseException');
              throw CredentialAlreadyInUseException(
                googleAuth: googleAuth,
                googleAccount: googleUser,
                previousGuestUid: previousGuestUid,
              );
            }
          } else {
            rethrow;
          }
        }
      } else {
        await _writeLog('linkWithGoogle | no current member, fresh Google sign-in');
        result = await _auth.signInWithCredential(credential);
      }

      final member = result.user!;
      await _writeLog('linkWithGoogle | result uid=${member.uid} | isAnonymous=${member.isAnonymous}');
      final deviceId = await DeviceUtils.getUniqueId();

      const maxRetries = 3;
      const retryDelays = [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)];
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await FunctionsService.linkGoogleAccount(
            email: member.email ?? googleUser.email,
            displayName: member.displayName ?? googleUser.displayName ?? '',
            deviceId: deviceId,
            previousGuestUid: previousGuestUid,
          );
          await _writeLog('linkWithGoogle | linkGoogleAccount cloud function succeeded');
          break;
        } catch (e) {
          await _writeLog('linkWithGoogle | linkGoogleAccount attempt ${attempt + 1} FAILED: $e');
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelays[attempt]);
          } else {
            rethrow;
          }
        }
      }

      await _writeLog('linkWithGoogle COMPLETED');
      return result;
    } catch (e) {
      await _writeLog('linkWithGoogle FAILED: $e');
      _googleAuthInProgress = false;
      if (e is CredentialAlreadyInUseException) rethrow;
      throw Exception('Authentication failed: $e');
    } finally {
      _googleAuthInProgress = false;
    }
  }

  /// Force sign-in with an existing Google account (credential-already-in-use).
  /// Wipes local guest data before switching.
  static Future<UserCredential> forceSignInWithExistingAccount({
    required GoogleSignInAuthentication googleAuth,
    required GoogleSignInAccount googleAccount,
    String? previousGuestUid,
  }) async {
    await _writeLog('forceSignInWithExistingAccount CALLED');
    _googleAuthInProgress = true;
    try {
      await DatabaseService.clearAll();
      DatabaseService.invalidateSuitesCache();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_display_name');
      await prefs.remove('is_returning_guest');
      await prefs.remove('stats_generations');
      await prefs.remove('stats_exports');
      await prefs.remove('stats_last_sync');
      await prefs.remove('is_pro');
      await prefs.setBool('pending_guest_creation', false);

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final result = await _auth.signInWithCredential(credential);
      final member = result.user!;
      await _writeLog('forceSignInWithExistingAccount | signed in as ${member.uid}');

      final deviceId = await DeviceUtils.getUniqueId();
      const maxRetries = 3;
      const retryDelays = [Duration(seconds: 1), Duration(seconds: 2), Duration(seconds: 4)];
      for (int attempt = 0; attempt < maxRetries; attempt++) {
        try {
          await FunctionsService.linkGoogleAccount(
            email: member.email ?? googleAccount.email,
            displayName: member.displayName ?? googleAccount.displayName ?? '',
            deviceId: deviceId,
            previousGuestUid: previousGuestUid,
          );
          await _writeLog('forceSignInWithExistingAccount | linkGoogleAccount succeeded');
          break;
        } catch (e) {
          await _writeLog('forceSignInWithExistingAccount | linkGoogleAccount attempt ${attempt + 1} FAILED: $e');
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelays[attempt]);
          } else {
            rethrow;
          }
        }
      }
      return result;
    } catch (e) {
      await _writeLog('forceSignInWithExistingAccount FAILED: $e');
      rethrow;
    } finally {
      _googleAuthInProgress = false;
    }
  }

  /// After Google sign-in, pull remote suites (if any).
  static Future<void> completePostLoginFlow() async {
    await AnalyticsService.logDebug(message: 'completePostLoginFlow: ENTER');
    try {
      await CloudSyncService.pullRemoteSuites();
      await AnalyticsService.logDebug(message: 'completePostLoginFlow: SUCCESS');
    } catch (e) {
      await AnalyticsService.logDebug(message: 'completePostLoginFlow: FAILED $e');
    }
  }

  // Sign out — no guest creation. Sets pending_guest_creation flag so
  // SplashScreen can auto-create a guest with a clean Firebase Auth state.
  static Future<void> signOut({bool revokeGoogleAccess = false}) async {
    SessionMonitor.stop();
    await AnalyticsService.logDebug(message: 'signOut: ENTER | revokeGoogleAccess=$revokeGoogleAccess');
    try {
      await _googleSignIn.signOut();
    } catch (e, _) {
      debugPrint('🔐 AuthService: Google sign-out error: $e');
    }
    if (revokeGoogleAccess) {
      try {
        await _googleSignIn.disconnect();
      } catch (e, _) {
        debugPrint('🔐 AuthService: Google disconnect error: $e');
      }
    }
    _googleAuthInProgress = false; // safety: unstick any stale guard

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

    // Set flag so SplashScreen can auto-create a guest in a clean context
    // after Firebase auth state is fully flushed.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('pending_guest_creation', true);
    } catch (e, _) {
      debugPrint('🔐 AuthService: failed to set pending_guest_creation: $e');
    }

    try {
      await _auth.signOut();
    } catch (e, _) {
      debugPrint('🔐 AuthService: Firebase sign-out error: $e');
    }

    // Clear local database so the new guest sees empty suites
    try {
      await DatabaseService.clearAll();
      DatabaseService.invalidateSuitesCache();
    } catch (e, _) {
      debugPrint('🔐 AuthService: DB clear error: $e');
    }

    // Re-initialize database under device-level identity
    try {
      final deviceId = await DeviceUtils.getUniqueId();
      await _reinitializeDb(deviceId);
    } catch (e, _) {
      debugPrint('🔐 AuthService: DB re-init error: $e');
    }
  }

  /// Hard sign-out: wipes local data, does NOT re-create guest.
  /// Used when the user is kicked out due to multi-device conflict.
  static Future<void> hardSignOut() async {
    SessionMonitor.stop();
    await AnalyticsService.logDebug(message: 'hardSignOut: ENTER');
    await DatabaseService.clearAll();
    DatabaseService.invalidateSuitesCache();
    try { await _googleSignIn.signOut(); } catch (_) {}
    try { await _auth.signOut(); } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final preserved = <String, dynamic>{};
      for (final k in ['first_launch_completed', 'never_show_guidelines', 'first_launch_guidelines_shown']) {
        final v = prefs.get(k);
        if (v != null) preserved[k] = v;
      }
      await prefs.clear();
      for (final e in preserved.entries) {
        final v = e.value;
        if (v is bool) await prefs.setBool(e.key, v);
        else if (v is String) await prefs.setString(e.key, v);
        else if (v is int) await prefs.setInt(e.key, v);
        else if (v is double) await prefs.setDouble(e.key, v);
      }
    } catch (_) {}
  }

  static Future<void> _reinitializeDb(String identity) async {
    await DatabaseService.initDatabase(identity);
    DatabaseService.invalidateSuitesCache();
  }
}
