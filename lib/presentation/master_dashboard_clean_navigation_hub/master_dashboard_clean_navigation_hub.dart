import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../available_leads_screen/available_leads_screen.dart';
import '../my_leads/my_leads_screen.dart';
import '../profile_screen_logout_integration/profile_screen_logout_integration.dart';
import './widgets/nav_card_widget.dart';

class MasterDashboardCleanNavigationHub extends StatefulWidget {
  const MasterDashboardCleanNavigationHub({super.key});

  @override
  State<MasterDashboardCleanNavigationHub> createState() =>
      _MasterDashboardCleanNavigationHubState();
}

class _MasterDashboardCleanNavigationHubState
    extends State<MasterDashboardCleanNavigationHub> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    _DashboardPage(),
    AvailableLeadsScreen(),
    MyLeadsScreen(),
    ProfileScreenLogoutIntegration(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Dashboard',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'Available Leads',
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
    ),
    _NavItem(
      label: 'My Leads',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final unselectedColor = isDark
        ? AppTheme.textMediumEmphasisDark
        : AppTheme.textMediumEmphasisLight;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
          border: Border(
            top: BorderSide(
              color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_navItems.length, (index) {
                final item = _navItems[index];
                final isSelected = _currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? item.activeIcon : item.icon,
                            key: ValueKey(isSelected),
                            color: isSelected ? selectedColor : unselectedColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 10.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.fastOutSlowIn,
                          height: 3,
                          width: isSelected ? 20 : 0,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardPage extends StatefulWidget {
  const _DashboardPage();

  @override
  State<_DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<_DashboardPage> {
  String? _masterName;
  bool _nameLoaded = false;

  @override
  void initState() {
    super.initState();
    _fetchMasterName();
  }

  Future<void> _fetchMasterName() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _nameLoaded = true);
        return;
      }
      final response = await Supabase.instance.client
          .from('users')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _masterName = response?['name'] as String?;
          _nameLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _nameLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final greeting = _nameLoaded
        ? (_masterName != null && _masterName!.isNotEmpty
              ? 'Welcome back, $_masterName!'
              : 'Welcome back!')
        : 'Welcome back!';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Dashboard',
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
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
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
              // 2x2 Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 3.w,
                  mainAxisSpacing: 2.h,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    NavCardWidget(
                      icon: Icons.search_rounded,
                      title: 'Available Leads',
                      subtitle: 'Browse open requests',
                      accentColor: isDark
                          ? AppTheme.primaryDark
                          : AppTheme.primaryLight,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.availableLeads,
                      ),
                    ),
                    NavCardWidget(
                      icon: Icons.assignment_rounded,
                      title: 'My Leads',
                      subtitle: 'View your accepted leads',
                      accentColor: AppTheme.successLight,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.myLeads),
                    ),
                    NavCardWidget(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Messages',
                      subtitle: 'Chat with clients',
                      accentColor: AppTheme.accentColor,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.realTimeMessaging,
                      ),
                    ),
                    NavCardWidget(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile',
                      subtitle: 'Manage your account',
                      accentColor: const Color(0xFF8B5CF6),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.profile),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
