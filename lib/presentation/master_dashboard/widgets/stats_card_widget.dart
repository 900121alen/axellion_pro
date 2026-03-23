import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StatsCardWidget extends StatelessWidget {
  final Map<String, dynamic> stat;

  const StatsCardWidget({super.key, required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stat['color'] as Color;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: stat['icon'] as String,
            color: color,
            size: 20,
          ),
          SizedBox(height: 0.8.h),
          Text(
            stat['value'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stat['label'] as String,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
