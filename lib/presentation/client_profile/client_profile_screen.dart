import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  bool _isLoggingOut = false;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('id, name, email, role, status, created_at')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _userProfile = response;
          _isLoadingProfile = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);

    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/login-screen', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _handleLogout,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AbsorbPointer(
      absorbing: _isLoggingOut,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          title: Text(
            'Profile',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/client-home'),
          ),
        ),
        body: _isLoadingProfile
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildProfileHeader(theme),
                    SizedBox(height: 2.h),
                    _buildInfoSection(theme),
                    SizedBox(height: 2.h),
                    _buildSettingsSection(theme),
                    SizedBox(height: 2.h),
                    _buildLogoutSection(theme),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme) {
    final name = _userProfile?['name'] as String? ?? 'User';
    final email = _userProfile?['email'] as String? ?? '';
    final role = _userProfile?['role'] as String? ?? 'client';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 4.w),
      decoration: BoxDecoration(color: theme.colorScheme.primary),
      child: Column(
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          Text(
            name,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            email,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ThemeData theme) {
    final status = _userProfile?['status'] as String? ?? 'active';
    final createdAt = _userProfile?['created_at'] as String?;
    String joinedDate = 'N/A';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt);
        joinedDate = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            _buildInfoTile(
              theme,
              icon: 'info',
              label: 'Account Status',
              value: status.toUpperCase(),
              valueColor: status == 'active'
                  ? AppTheme.successLight
                  : theme.colorScheme.error,
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildInfoTile(
              theme,
              icon: 'calendar_today',
              label: 'Member Since',
              value: joinedDate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Text(
                'Settings',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildSettingsTile(
              theme,
              icon: 'notifications_outlined',
              label: 'Notifications',
              onTap: () {},
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildSettingsTile(
              theme,
              icon: 'lock_outline',
              label: 'Change Password',
              onTap: () {},
            ),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            _buildSettingsTile(
              theme,
              icon: 'help_outline',
              label: 'Help & Support',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: ListTile(
          onTap: _isLoggingOut ? null : _handleLogout,
          leading: _isLoggingOut
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.red,
                  ),
                )
              : const Icon(Icons.logout_rounded, color: Colors.red),
          title: Text(
            _isLoggingOut ? 'Signing out...' : 'Sign Out',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: _isLoggingOut
              ? null
              : const Icon(Icons.chevron_right_rounded, color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    ThemeData theme, {
    required String icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    ThemeData theme, {
    required String icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: CustomIconWidget(
        iconName: icon,
        color: theme.colorScheme.onSurfaceVariant,
        size: 22,
      ),
      title: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
