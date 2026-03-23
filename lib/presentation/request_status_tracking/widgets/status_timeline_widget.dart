import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class StatusTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> statusSteps;
  final int currentStepIndex;

  const StatusTimelineWidget({
    super.key,
    required this.statusSteps,
    required this.currentStepIndex,
  });

  Color _getStatusColor(String status, BuildContext context) {
    final theme = Theme.of(context);
    switch (status) {
      case 'completed':
        return AppTheme.successLight;
      case 'active':
        return theme.colorScheme.primary;
      case 'cancelled':
        return AppTheme.errorLight;
      case 'pending':
        return theme.colorScheme.onSurfaceVariant;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getStatusIcon(String stepName) {
    switch (stepName) {
      case 'Searching':
        return Icons.search_rounded;
      case 'Assigned':
        return Icons.person_pin_rounded;
      case 'Scheduled':
        return Icons.event_available_rounded;
      case 'In Progress':
        return Icons.build_rounded;
      case 'Completed':
        return Icons.check_circle_rounded;
      case 'Relisted':
        return Icons.refresh_rounded;
      case 'Archived':
        return Icons.archive_rounded;
      case 'Cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(statusSteps.length, (index) {
        final step = statusSteps[index];
        final stepStatus = step['status'] as String;
        final isLast = index == statusSteps.length - 1;
        final color = _getStatusColor(stepStatus, context);
        final isActive = stepStatus == 'active';
        final isCompleted = stepStatus == 'completed';
        final isCancelled = stepStatus == 'cancelled';

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 10.w,
                child: Column(
                  children: [
                    Container(
                      width: 10.w,
                      height: 10.w,
                      decoration: BoxDecoration(
                        color: (isActive || isCompleted || isCancelled)
                            ? color
                            : color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: (isActive || isCancelled)
                            ? Border.all(color: color, width: 2)
                            : null,
                        boxShadow: (isActive || isCancelled)
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: CustomIconWidget(
                          iconName: isCompleted
                              ? 'check'
                              : _getStatusIcon(
                                  step['title'] as String,
                                ).codePoint.toString(),
                          color: (isActive || isCompleted || isCancelled)
                              ? Colors.white
                              : color,
                          size: 4.w,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: isCompleted
                              ? AppTheme.successLight
                              : theme.colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 3.8.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step['title'] as String,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: (isActive || isCancelled)
                                    ? color
                                    : theme.colorScheme.onSurface,
                                fontWeight: (isActive || isCancelled)
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (step['timestamp'] != null)
                            Text(
                              step['timestamp'] as String,
                              style: theme.textTheme.labelSmall,
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        step['description'] as String,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isActive || isCancelled) ...[
                        SizedBox(height: 1.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 1.w),
                              Text(
                                isCancelled ? 'Cancelled' : 'Current Step',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
