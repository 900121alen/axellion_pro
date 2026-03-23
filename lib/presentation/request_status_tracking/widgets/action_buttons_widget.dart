import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final String currentStatus;
  final VoidCallback onCancel;
  final VoidCallback onContact;
  final VoidCallback onMarkComplete;
  final VoidCallback onRelist;

  const ActionButtonsWidget({
    super.key,
    required this.currentStatus,
    required this.onCancel,
    required this.onContact,
    required this.onMarkComplete,
    required this.onRelist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.colorScheme.outline)),
      ),
      child: _buildButtons(context, theme),
    );
  }

  Widget _buildButtons(BuildContext context, ThemeData theme) {
    switch (currentStatus) {
      case 'Searching':
      case 'Assigned':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: CustomIconWidget(
                  iconName: 'cancel',
                  color: AppTheme.errorLight,
                  size: 18,
                ),
                label: const Text('Cancel Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorLight,
                  side: const BorderSide(color: AppTheme.errorLight),
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            if (currentStatus == 'Assigned') ...[
              SizedBox(width: 3.w),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onContact,
                  icon: CustomIconWidget(
                    iconName: 'chat',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Contact Master'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                ),
              ),
            ],
          ],
        );
      case 'In Progress':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onContact,
                icon: CustomIconWidget(
                  iconName: 'chat',
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
                label: const Text('Contact Master'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onMarkComplete,
                icon: CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text('Mark Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successLight,
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),
          ],
        );
      case 'Cancelled':
      case 'Relisted':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRelist,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 18,
            ),
            label: const Text('Relist Request'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
