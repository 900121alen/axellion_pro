import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import './client_home_screen.dart';

class ClientHome extends StatefulWidget {
  const ClientHome({super.key});

  @override
  ClientHomeState createState() => ClientHomeState();
}

class ClientHomeState extends State<ClientHome> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  int currentIndex = 0;
  int _unreadCount = 0;
  RealtimeChannel? _messageChannel;

  final List<String> _routes = [
    AppRoutes.clientHome,
    AppRoutes.myRequests,
    AppRoutes.clientMessages,
    AppRoutes.clientProfile,
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _NavItem(
      label: 'My Requests',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
    ),
    _NavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnreadCount();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final response = await Supabase.instance.client
          .from('messages')
          .select('id')
          .eq('receiver_id', userId)
          .isFilter('read_at', null);
      if (mounted) {
        setState(() {
          _unreadCount = (response as List).length;
        });
      }
    } catch (_) {}
  }

  void _subscribeToMessages() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _messageChannel = Supabase.instance.client
        .channel('client_home_unread_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            _fetchUnreadCount();
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        initialRoute: AppRoutes.clientHome,
        onGenerateRoute: (settings) {
          switch (settings.name) {
            case '/client-home':
              return MaterialPageRoute(
                builder: (_) => const ClientHomeScreen(),
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
                builder: (_) => const ClientHomeScreen(),
              );
          }
        },
      ),
      bottomNavigationBar: _RoleBottomBar(
        currentIndex: currentIndex,
        items: _navItems,
        unreadCount: _unreadCount,
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

class _RoleBottomBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final Function(int) onTap;
  final int unreadCount;

  const _RoleBottomBar({
    required this.currentIndex,
    required this.items,
    required this.onTap,
    required this.unreadCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const neonBlue = Color(0xFF3A8BFF);
    const darkNavBg = Color(0xFF0D0D1A);
    const darkNavBorder = Color(0xFF1C1C2E);
    final unselectedColor = isDark
        ? const Color(0xFF6B7280)
        : AppTheme.textMediumEmphasisLight;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? darkNavBg : AppTheme.surfaceLight,
        border: Border(
          top: BorderSide(
            color: isDark ? darkNavBorder : AppTheme.borderLight,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : AppTheme.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 90,
          child: Row(
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;
              final isMessages = index == 2;
              final showBadge = isMessages && unreadCount > 0;
              final badgeLabel = unreadCount > 9 ? '9+' : '$unreadCount';

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? neonBlue.withValues(alpha: 0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24.0),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: neonBlue.withValues(alpha: 0.3),
                                    blurRadius: 14,
                                    spreadRadius: 0,
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              isSelected ? item.activeIcon : item.icon,
                              color: isSelected ? neonBlue : unselectedColor,
                              size: 28,
                            ),
                            if (showBadge)
                              Positioned(
                                top: -6,
                                right: -8,
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 18,
                                    minHeight: 18,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Text(
                                    badgeLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected ? neonBlue : unselectedColor,
                        ),
                        overflow: TextOverflow.ellipsis,
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
