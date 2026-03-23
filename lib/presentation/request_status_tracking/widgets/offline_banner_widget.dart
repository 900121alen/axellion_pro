import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class OfflineBannerWidget extends StatelessWidget {
  final String lastUpdated;

  const OfflineBannerWidget({super.key, required this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      color: AppTheme.accentColor.withValues(alpha: 0.15),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'wifi_off',
            color: AppTheme.accentColor,
            size: 16,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Offline — Last updated: $lastUpdated',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          CustomIconWidget(
            iconName: 'sync',
            color: AppTheme.accentColor,
            size: 16,
          ),
        ],
      ),
    );
  }
}
