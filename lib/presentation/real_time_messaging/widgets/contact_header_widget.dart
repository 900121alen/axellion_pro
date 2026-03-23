import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ContactHeaderWidget extends StatelessWidget {
  final String participantName;
  final bool isOnline;
  final bool isTyping;
  final DateTime? lastSeen;
  final VoidCallback? onBackPressed;
  final VoidCallback? onCalendarTap;
  final DateTime? serviceTime;
  final DateTime? serviceTimeEnd;

  const ContactHeaderWidget({
    super.key,
    required this.participantName,
    required this.isOnline,
    required this.isTyping,
    this.lastSeen,
    this.onBackPressed,
    this.onCalendarTap,
    this.serviceTime,
    this.serviceTimeEnd,
  });

  String _formatScheduledBar(DateTime dt, DateTime? end) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dt.month - 1];
    final day = dt.day;
    final startH = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final startM = dt.minute.toString().padLeft(2, '0');
    final startPeriod = dt.hour >= 12 ? 'PM' : 'AM';
    final startStr = '$startH:$startM $startPeriod';

    if (end != null) {
      final endH = end.hour > 12
          ? end.hour - 12
          : (end.hour == 0 ? 12 : end.hour);
      final endM = end.minute.toString().padLeft(2, '0');
      final endPeriod = end.hour >= 12 ? 'PM' : 'AM';
      return '$month $day  •  $startStr – $endH:$endM $endPeriod';
    }
    return '$month $day  •  $startStr';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final avatarLetter = participantName.isNotEmpty
        ? participantName[0].toUpperCase()
        : '';

    final statusText = isOnline ? '● online' : '● offline';
    final statusColor = isOnline ? AppTheme.successLight : Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            border: Border(
              bottom: BorderSide(
                color: serviceTime != null
                    ? Colors.transparent
                    : (isDark ? AppTheme.dividerDark : AppTheme.borderLight),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppTheme.primaryLight.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      avatarLetter,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isOnline ? AppTheme.successLight : Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.surfaceDark
                              : AppTheme.surfaceLight,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participantName.isNotEmpty
                          ? participantName
                          : 'Loading...',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    isTyping
                        ? Text(
                            'typing...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.secondaryLight,
                              fontSize: 10.sp,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        : Text(
                            statusText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10.sp,
                              color: statusColor,
                              overflow: TextOverflow.ellipsis,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                  ],
                ),
              ),
              if (onCalendarTap != null)
                IconButton(
                  icon: Icon(
                    Icons.calendar_month_outlined,
                    color: isDark
                        ? AppTheme.primaryDark
                        : AppTheme.primaryLight,
                    size: 22,
                  ),
                  onPressed: onCalendarTap,
                  tooltip: 'Schedule Service',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
            ],
          ),
        ),
        if (serviceTime != null)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.08),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppTheme.primaryLight,
                ),
                SizedBox(width: 6),
                Text(
                  _formatScheduledBar(serviceTime!, serviceTimeEnd),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
