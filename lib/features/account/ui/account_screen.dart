import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qa_genie/app/theme/app_theme.dart';
import 'package:qa_genie/app/theme/app_colors.dart';
import 'package:qa_genie/app/theme/app_radius.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qa_genie/features/auth/ui/auth_dialog.dart';
import 'package:qa_genie/features/legal/ui/about_screen.dart';
import 'package:qa_genie/features/auth/services/auth_service.dart';
import 'package:qa_genie/features/legal/ui/terms_privacy_policy.dart';
import 'package:qa_genie/features/support/ui/report_issue_screen.dart';
import 'package:qa_genie/features/monetization/ui/upgrade_screen.dart';
import 'package:qa_genie/features/monetization/logic/usage_manager.dart';
import 'package:qa_genie/firebase/cloud_functions/functions_service.dart';
import 'package:qa_genie/core/database/database_service.dart';
import 'package:qa_genie/core/network/network_guard.dart';
import 'package:qa_genie/core/utils/device_utils.dart';
import 'package:qa_genie/core/utils/dialog_utils.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  static bool _pendingRefresh = false;
  static void markForRefresh() => _pendingRefresh = true;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  User? _user;
  bool _isPro = false;
  int _totalGenerations = 0;
  int _totalExports = 0;
  DateTime? _memberSince;
  bool _isSyncing = false;
  String? _lastSyncedText;
  String _appVersion = '';
  String _guestDisplayName = '';

  @override
  void initState() {
    super.initState();
    _user = AuthService.currentUser;
    _loadVersion();
    _loadCachedData();
    _refreshIsPro();
    if (AccountScreen._pendingRefresh) {
      AccountScreen._pendingRefresh = false;
      _loadData();
    }
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = packageInfo.version);
  }

  Future<void> _refreshIsPro() async {
    final pro = await UsageManager.isPro();
    if (mounted) setState(() => _isPro = pro);
  }

  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final generations = prefs.getInt('stats_generations') ?? 0;
    final exports = prefs.getInt('stats_exports') ?? 0;
    final lastSync = prefs.getInt('stats_last_sync') ?? 0;
    final cachedGuestName = prefs.getString('guest_display_name') ?? '';

    if (mounted) {
      setState(() {
        _totalGenerations = generations;
        _totalExports = exports;
        _guestDisplayName = cachedGuestName;
        if (lastSync > 0) {
          final diff = DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(lastSync),
          );
          if (diff.inMinutes < 1) {
            _lastSyncedText = 'Sync just now';
          } else if (diff.inMinutes < 60) {
            _lastSyncedText = '${diff.inMinutes}m ago';
          } else if (diff.inHours < 24) {
            _lastSyncedText = '${diff.inHours}h ago';
          } else if (diff.inDays < 30) {
            _lastSyncedText = '${diff.inDays}d ago';
          } else {
            _lastSyncedText = '${(diff.inDays / 30).floor()}mo ago';
          }
        } else {
          _lastSyncedText = 'Syncing...';
        }
      });
    }
  }

  Future<void> _loadData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);

    final user = AuthService.currentUser;
    final isPro = await UsageManager.isPro();

    int generations = _totalGenerations;
    int exports = _totalExports;
    DateTime? memberSince;

    try {
      final stats = await UsageManager.getLifetimeStats();
      generations = stats['generations'] ?? 0;
      exports = stats['exports'] ?? 0;

      if (user != null) {
        final dashboard = await UsageManager.getDashboardData();
        final identity = dashboard['identity'] as Map?;
        if (identity != null) {
          // Parse creation date for both users and guests
          final createdAt = identity['createdAt'];
          if (createdAt is String) {
            memberSince = DateTime.parse(createdAt);
          }
          final isGuestUser = AuthService.isGuest;
          if (isGuestUser) {
            final name = identity['displayName'] as String?;
            if (name != null && name.isNotEmpty) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('guest_display_name', name);
              if (mounted) _guestDisplayName = name;
            }
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('stats_generations', generations);
      await prefs.setInt('stats_exports', exports);
      await prefs.setInt(
        'stats_last_sync',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('AccountScreen: Error loading data: $e');
    }

      if (mounted) {
        setState(() {
          _user = user;
          _isPro = isPro;
          _totalGenerations = generations;
          _totalExports = exports;
          _memberSince = memberSince;
          _guestDisplayName = _guestDisplayName;
          _isSyncing = false;
          _lastSyncedText = 'Sync just now';
        });
      }
  }

  Future<void> _confirmLogout() async {
    if (!await NetworkGuard.ensureProductionOnline(context)) return;

    final confirmed = await showBlurredDialog<bool>(context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'You will be signed out of your Google account and switched to a guest session. Your data will remain saved if you sign back in.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) _logout();
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('stats_generations');
    await prefs.remove('stats_exports');
    await prefs.remove('stats_last_sync');
    await AuthService.signOut();

    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      AccountScreen.markForRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = AuthService.isGuest;
    final email = _user?.email ?? '';
    final displayName = _user?.displayName ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Account', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        // Removed logout icon from app bar
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              _buildInfoCard(isGuest, email, displayName),
              const SizedBox(height: 16),
              _buildMenuCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    if (!await NetworkGuard.ensureProductionOnline(context)) return;

    final textController = TextEditingController();
    final confirmed = await showBlurredDialog<bool>(context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will permanently delete all your data, including generations and exports. This cannot be undone.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type "DELETE" to confirm',
              style: TextStyle(color: AppColors.textHint, fontSize: 12),
            ),
            TextField(
              controller: textController,
              decoration: const InputDecoration(hintText: 'DELETE'),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text == 'DELETE') {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) _deleteAccount();
  }

  Future<void> _deleteAccount() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final deviceId = await DeviceUtils.getUniqueId();
      final user = AuthService.currentUser;
      await FunctionsService.call(functionName: 'deleteAccount', payload: {
        'deviceId': deviceId,
        if (user != null && !user.isAnonymous) 'email': user.email,
      });
      await DatabaseService.clearAll();
      await _logout();
    } catch (e) {
      if (mounted) {
        showBlurredDialog(
          context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Account Deletion Failed', style: TextStyle(color: Colors.white)),
            content: Text(
              'Unable to delete your account at this time. Please try again later.',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK', style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      }
    }
  }


  Widget _buildInfoCard(bool isGuest, String email, String displayName) {
    final name = isGuest
        ? (_guestDisplayName.isNotEmpty
            ? _guestDisplayName
            : displayName.isNotEmpty
                ? displayName
                : 'Guest')
        : (displayName.isNotEmpty ? displayName : email.split('@').first);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (!isGuest)
            Text(
              email,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isPro ? 'PRO' : 'CORE',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statColumn('Generated', _totalGenerations),
              const SizedBox(width: 40),
              _statColumn('Exported', _totalExports),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Joined ${_memberSince != null ? _formatDate(_memberSince!) : '...'} • ${_lastSyncedText ?? 'Syncing...'}',
            style: const TextStyle(fontSize: 11, color: AppColors.textHint),
          ),
          if (isGuest) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _showAuthDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Continue with Google'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statColumn(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textHint),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${_monthAbbr(date.month)} ${date.year}';
  }

  String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildMenuCard() {
    final isGuest = AuthService.isGuest;
    final isAnonymous = (_user?.isAnonymous ?? true) || isGuest;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.support_agent,
            title: 'Report an Issue',
            subtitle: 'Help us improve QA Genie',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIssueScreen()),
            ),
          ),
          _divider(),
          _menuItem(
            icon: Icons.stars,
            title: 'QA Genie Pro',
            subtitle: 'Coming soon',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpgradeScreen()),
            ),
          ),
          _divider(),
          // Sign Out + Delete Account for signed-in users only
          if (!isAnonymous) ...[
            _divider(),
            _menuItem(
              icon: Icons.logout,
              title: 'Sign Out',
              subtitle: 'Log out of your account',
              onTap: _confirmLogout,
            ),
            _divider(),
            _menuItem(
              icon: Icons.delete_forever,
              title: 'Delete Account',
              subtitle: 'Permanently remove all data',
              onTap: _confirmDeleteAccount,
              isDestructive: true,
            ),
          ],
          _divider(),
          _menuItem(
            icon: Icons.description,
            title: 'Policies',
            subtitle: 'Terms & Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TermsPrivacyPolicyScreen(),
              ),
            ),
          ),
          _divider(),
          _menuItem(
            icon: Icons.info_outline,
            title: 'About QA Genie',
            subtitle: 'Version $_appVersion',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
          _divider(),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: const Text(
              'Data stays local on this device and is not synced to the cloud.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.accent,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? AppColors.error : Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: AppText.hint),
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textHint,
        size: 20,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _divider() => Divider(
    height: 1,
    thickness: 0.5,
    color: AppColors.border.withOpacity(0.5),
  );

  void _showAuthDialog() async {
    if (!await NetworkGuard.ensureProductionOnline(context)) return;

    await showBlurredDialog(context,
      builder: (ctx) => const AuthDialog(showGuestButton: false),
    );
    if (mounted) _loadData();
  }
}
