import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';
import './master_dashboard_initial_page.dart';
import '../available_leads_screen/available_leads_screen.dart';
import '../my_leads/my_leads_screen.dart';
import '../profile_screen_logout_integration/profile_screen_logout_integration.dart';

class MasterDashboard extends StatefulWidget {
  const MasterDashboard({super.key});

  @override
  MasterDashboardState createState() => MasterDashboardState();
}

class MasterDashboardState extends State<MasterDashboard> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MasterDashboardInitialPage(),
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
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected ? selectedColor : unselectedColor,
                          ),
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
