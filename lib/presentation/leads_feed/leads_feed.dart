import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './leads_feed_initial_page.dart';

class LeadsFeed extends StatefulWidget {
  const LeadsFeed({super.key});

  @override
  LeadsFeedState createState() => LeadsFeedState();
}

class LeadsFeedState extends State<LeadsFeed> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;

  final List<String> _routes = [
    AppRoutes.availableLeads,
    AppRoutes.myLeads,
    AppRoutes.profile,
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Leads Feed',
      icon: Icons.dynamic_feed_outlined,
      activeIcon: Icons.dynamic_feed_rounded,
    ),
    _NavItem(
      label: 'My Leads',
      icon: Icons.bookmark_border_rounded,
      activeIcon: Icons.bookmark_rounded,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: AppRoutes.availableLeads,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/leads-feed':
              return MaterialPageRoute(
                builder: (_) => const LeadsFeedInitialPage(),
                settings: settings,
              );
            default:
              if (AppRoutes.routes.containsKey(settings.name)) {
                return MaterialPageRoute(
                  builder: AppRoutes.routes[settings.name]!,
                  settings: settings,
                );
              }
              return MaterialPageRoute(
                builder: (_) => const LeadsFeedInitialPage(),
              );
          }
        },
      ),
      bottomNavigationBar: _MasterBottomBar(
        currentIndex: currentIndex,
        items: _navItems,
        onTap: (index) {
          if (currentIndex != index) {
            setState(() => currentIndex = index);
            navigatorKey.currentState?.pushReplacementNamed(_routes[index]);
          }
        },
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

class _MasterBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Function(int) onTap;

  const _MasterBottomBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = isDark ? AppTheme.primaryDark : AppTheme.primaryLight;
    final unselectedColor = isDark
        ? AppTheme.textMediumEmphasisDark
        : AppTheme.textMediumEmphasisLight;

    return Container(
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
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? selectedColor : unselectedColor,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
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
    );
  }
}
