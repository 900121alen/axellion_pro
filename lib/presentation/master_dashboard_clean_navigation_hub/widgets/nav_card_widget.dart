import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart';

class NavCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const NavCardWidget({
    super.key,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!kIsWeb) HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2D3D) : Colors.white,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: isDark ? 0.08 : 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.4.h),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
