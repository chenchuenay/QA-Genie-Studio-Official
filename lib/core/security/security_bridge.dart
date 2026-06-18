import 'package:qa_genie/core/config/app_environment.dart';
import 'package:qa_genie/core/network/cloud_authority_service.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
// ============================================================
// FILE: lib/core/security/security_bridge.dart
// ============================================================

/// ===============================================================
///
/// SECURITY BRIDGE
///
/// SINGLE ENTRY POINT FOR SECURITY AUTHORITY.
///
/// IMPORTANT:
/// UI / ENGINE / SERVICES MUST NEVER KNOW:
/// - if app is DEV or PROD
/// - if token is local or cloud
/// - if quota is mocked or server-driven
///
/// EVERYTHING goes through this bridge.
///
/// ===============================================================

abstract class ISecurityService {
  // ============================================================
  // AUTHORITY
  // ============================================================

  Future<String> acquireGenerationToken({required String actionType});

  // ============================================================
  // QUOTA
  // ============================================================

  Future<bool> canGenerate();

  Future<void> trackGeneration();

  // ============================================================
  // ENVIRONMENT
  // ============================================================

  bool get canBypassLimits;

  bool get isProduction;

  // ============================================================
  // CLEANUP
  // ============================================================

  Future<void> dispose();
}

/// ===============================================================
///
/// SECURITY BRIDGE FACTORY
///
/// ===============================================================
class SecurityBridge {
  const SecurityBridge._();

  static ISecurityService? _instance;

  static ISecurityService get instance {
    _instance ??= _create();
    return _instance!;
  }

  static ISecurityService _create() {
    if (EnvironmentAuthority.isProd) {
      return ProductionSecurityService(
        cloudAuthorityService: CloudAuthorityService(),
      );
    }

    return DevSecurityService();
  }

  static Future<void> reset() async {
    await _instance?.dispose();
    _instance = null;
  }
}

/// ===============================================================
///
/// DEV SECURITY SERVICE
///
/// INTERNAL TESTING MODE ONLY.
///
/// ===============================================================
class DevSecurityService implements ISecurityService {
  // ============================================================
  // DEV LIMITS
  // ============================================================

  static const int _freeGenerationLimit = 1;

  static const int _rewardedGenerationLimit = 5;

  int _usedFreeGenerations = 0;

  int _usedRewardedGenerations = 0;

  // ============================================================
  // TOKEN
  // ============================================================

  @override
  Future<String> acquireGenerationToken({required String actionType}) async {
    return 'DEV_LOCAL_TOKEN_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ============================================================
  // QUOTA
  // ============================================================

  @override
  Future<bool> canGenerate() async {
    final totalUsed = _usedFreeGenerations + _usedRewardedGenerations;

    return totalUsed < (_freeGenerationLimit + _rewardedGenerationLimit);
  }

  @override
  Future<void> trackGeneration() async {
    final totalUsed = _usedFreeGenerations + _usedRewardedGenerations;

    if (totalUsed == 0) {
      _usedFreeGenerations++;
    } else {
      _usedRewardedGenerations++;
    }
  }

  // ============================================================
  // DEV HELPERS
  // ============================================================

  void resetDevQuota() {
    _usedFreeGenerations = 0;
    _usedRewardedGenerations = 0;
  }

  int get remainingDevGenerations {
    final used = _usedFreeGenerations + _usedRewardedGenerations;

    return (_freeGenerationLimit + _rewardedGenerationLimit) - used;
  }

  // ============================================================
  // ENVIRONMENT
  // ============================================================

  @override
  bool get canBypassLimits => true;

  @override
  bool get isProduction => false;

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  Future<void> dispose() async {}
}

/// ===============================================================
///
/// PRODUCTION SECURITY SERVICE
///
/// REAL CLOUD AUTHORITY.
///
/// ===============================================================
class ProductionSecurityService implements ISecurityService {
  final CloudAuthorityService cloudAuthorityService;

  ProductionSecurityService({required this.cloudAuthorityService});

  // ============================================================
  // TOKEN
  // ============================================================

  @override
  Future<String> acquireGenerationToken({required String actionType}) async {
    throw UnimplementedError('acquireGenerationToken not wired');
  }

  // ============================================================
  // QUOTA
  // ============================================================

  @override
  Future<bool> canGenerate() async {
    return cloudAuthorityService.canGenerate();
  }

  @override
  Future<void> trackGeneration() async {
    await FunctionsService.trackGenerationUsage();
  }

  // ============================================================
  // ENVIRONMENT
  // ============================================================

  @override
  bool get canBypassLimits => false;

  @override
  bool get isProduction => true;

  // ============================================================
  // CLEANUP
  // ============================================================

  @override
  Future<void> dispose() async {}
}
