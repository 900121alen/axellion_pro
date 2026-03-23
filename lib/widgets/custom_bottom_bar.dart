import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const List<_BottomNavItem> _items = [
    _BottomNavItem(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: '/master-dashboard',
    ),
    _BottomNavItem(
      label: 'Requests',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      route: '/service-request-creation',
    ),
    _BottomNavItem(
      label: 'Messages',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      route: '/real-time-messaging',
    ),
    _BottomNavItem(
      label: 'Tracking',
      icon: Icons.track_changes_outlined,
      activeIcon: Icons.track_changes_rounded,
      route: '/request-status-tracking',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final isSelected = currentIndex == index;
              return Expanded(
                child: _BottomNavItemWidget(
                  item: item,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _BottomNavItemWidget extends StatefulWidget {
  final _BottomNavItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _BottomNavItemWidget({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_BottomNavItemWidget> createState() => _BottomNavItemWidgetState();
}

class _BottomNavItemWidgetState extends State<_BottomNavItemWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.isDark
        ? AppTheme.primaryDark
        : AppTheme.primaryLight;
    final unselectedColor = widget.isDark
        ? AppTheme.textMediumEmphasisDark
        : AppTheme.textMediumEmphasisLight;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnimation.value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              ),
              child: Icon(
                widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                key: ValueKey(widget.isSelected),
                color: widget.isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: widget.isSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: widget.isSelected ? selectedColor : unselectedColor,
                letterSpacing: 0.2,
              ),
              child: Text(widget.item.label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.fastOutSlowIn,
              height: 3,
              width: widget.isSelected ? 20 : 0,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}
