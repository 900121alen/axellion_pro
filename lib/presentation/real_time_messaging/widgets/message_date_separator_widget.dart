import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class MessageDateSeparatorWidget extends StatelessWidget {
  final String date;

  const MessageDateSeparatorWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.5.h),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.cardDark
                    : AppTheme.primaryLight.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                date,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppTheme.textMediumEmphasisDark
                      : AppTheme.primaryLight,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
            ),
          ),
        ],
      ),
    );
  }
}
