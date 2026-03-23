import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum CustomAppBarVariant { standard, transparent, elevated }

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final bool centerTitle;
  final CustomAppBarVariant variant;
  final VoidCallback? onBackPressed;
  final double elevation;
  final Color? backgroundColor;
  final Widget? bottom;
  final double bottomHeight;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.centerTitle = true,
    this.variant = CustomAppBarVariant.standard,
    this.onBackPressed,
    this.elevation = 0,
    this.backgroundColor,
    this.bottom,
    this.bottomHeight = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + bottomHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = Navigator.of(context).canPop();

    Color resolvedBg;
    Color resolvedFg;
    SystemUiOverlayStyle overlayStyle;

    switch (variant) {
      case CustomAppBarVariant.transparent:
        resolvedBg = Colors.transparent;
        resolvedFg = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;
        overlayStyle = isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        break;
      case CustomAppBarVariant.elevated:
        resolvedBg = isDark ? AppTheme.surfaceDark : AppTheme.primaryLight;
        resolvedFg = isDark ? AppTheme.onSurfaceDark : AppTheme.onPrimaryLight;
        overlayStyle = isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.light;
        break;
      case CustomAppBarVariant.standard:
      default:
        resolvedBg =
            backgroundColor ??
            (isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight);
        resolvedFg = isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight;
        overlayStyle = isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
    }

    Widget? leadingWidget;
    if (leading != null) {
      leadingWidget = leading;
    } else if (showBackButton && canPop) {
      leadingWidget = _BackButton(
        color: resolvedFg,
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Container(
        decoration: variant == CustomAppBarVariant.standard
            ? BoxDecoration(
                color: resolvedBg,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                    width: 1,
                  ),
                ),
              )
            : BoxDecoration(
                color: resolvedBg,
                boxShadow: variant == CustomAppBarVariant.elevated
                    ? AppTheme.floatingShadow
                    : null,
              ),
        child: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: resolvedFg,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: centerTitle,
          leading: leadingWidget,
          automaticallyImplyLeading: false,
          title:
              titleWidget ??
              (title != null
                  ? Text(
                      title!,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: resolvedFg,
                        letterSpacing: 0,
                      ),
                    )
                  : null),
          actions: actions != null
              ? [...actions!, const SizedBox(width: 4)]
              : null,
          bottom: bottom != null
              ? PreferredSize(
                  preferredSize: Size.fromHeight(bottomHeight),
                  child: bottom!,
                )
              : null,
        ),
      ),
    );
  }
}

class _BackButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;

  const _BackButton({required this.color, required this.onPressed});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.all(8),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: widget.color,
            size: 18,
          ),
        ),
      ),
    );
  }
}
