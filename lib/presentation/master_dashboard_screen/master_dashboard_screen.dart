import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

class MasterDashboardScreen extends StatefulWidget {
  const MasterDashboardScreen({super.key});

  @override
  State<MasterDashboardScreen> createState() => _MasterDashboardScreenState();
}

class _MasterDashboardScreenState extends State<MasterDashboardScreen> {
  String? _masterName;

  @override
  void initState() {
    super.initState();
    _fetchMasterName();
  }

  Future<void> _fetchMasterName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _masterName = response?['name'] as String?;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greeting = _masterName != null && _masterName!.isNotEmpty
        ? 'Welcome, $_masterName!'
        : 'Welcome back!';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Master Dashboard',
          style: GoogleFonts.dmSans(
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.dmSans(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.6.h),
              Text(
                'What would you like to do today?',
                style: GoogleFonts.dmSans(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
              SizedBox(height: 3.h),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 3.w,
                mainAxisSpacing: 2.h,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _NavCard(
                    icon: Icons.search_rounded,
                    title: 'Available Leads',
                    subtitle: 'Browse open requests',
                    accentColor: isDark
                        ? AppTheme.primaryDark
                        : AppTheme.primaryLight,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.availableLeads),
                  ),
                  _NavCard(
                    icon: Icons.assignment_rounded,
                    title: 'My Leads',
                    subtitle: 'View accepted leads',
                    accentColor: AppTheme.successLight,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.myLeads),
                  ),
                  _NavCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Messages',
                    subtitle: 'Chat with clients',
                    accentColor: AppTheme.accentColor,
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.masterMessages),
                  ),
                  _NavCard(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    subtitle: 'Manage your account',
                    accentColor: const Color(0xFF8B5CF6),
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.masterProfile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (!kIsWeb) HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            SizedBox(height: 1.5.h),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 0.3.h),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 10.sp,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
