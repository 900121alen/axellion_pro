import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../widgets/custom_icon_widget.dart';

class RoleSelectorWidget extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool isLoading;

  const RoleSelectorWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isLoading,
  });

  static const List<Map<String, String>> _roles = [
    {
      'key': 'client',
      'label': 'Client',
      'icon': 'person',
      'desc': 'I need services',
    },
    {
      'key': 'master',
      'label': 'Master',
      'icon': 'build',
      'desc': 'I provide services',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 1.2.h),
        Row(
          children: _roles.map((role) {
            final isSelected = selectedRole == role['key'];
            final isLast = role['key'] == _roles.last['key'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 3.w),
                child: GestureDetector(
                  onTap: isLoading ? null : () => onRoleChanged(role['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.symmetric(
                      vertical: 1.5.h,
                      horizontal: 3.w,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : theme.colorScheme.surface,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        CustomIconWidget(
                          iconName: role['icon']!,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          role['label']!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          role['desc']!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
