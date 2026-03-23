import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class RoleSelectionWidget extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;
  final bool isLoading;

  const RoleSelectionWidget({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.isLoading,
  });

  static const List<Map<String, String>> _roles = [
    {'key': 'client', 'label': 'Client', 'icon': 'person'},
    {'key': 'master', 'label': 'Master', 'icon': 'build'},
    {'key': 'admin', 'label': 'Admin', 'icon': 'admin_panel_settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Login as',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 1.2.h),
        Row(
          children: _roles.map((role) {
            final isSelected = selectedRole == role['key'];
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: role['key'] != 'admin' ? 2.w : 0,
                ),
                child: GestureDetector(
                  onTap: isLoading ? null : () => onRoleChanged(role['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 5.5.h,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: role['icon']!,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                          size: 16,
                        ),
                        SizedBox(width: 1.5.w),
                        Text(
                          role['label']!,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
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
