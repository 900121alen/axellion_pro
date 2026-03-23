import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AvailableLeadCardWidget extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback onDetails;
  final VoidCallback onBuyLead;

  const AvailableLeadCardWidget({
    super.key,
    required this.lead,
    required this.onDetails,
    required this.onBuyLead,
  });

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryNameFromJoin =
        (lead['categories'] as Map<String, dynamic>?)?['name'] as String?;
    final categoryNameDirect = lead['category_name'] as String?;
    final serviceName = lead['service_name'] as String?;
    final categoryName =
        categoryNameDirect ?? categoryNameFromJoin ?? 'Service';
    final description = lead['description'] as String? ?? '';
    final areaName = lead['area_name'] as String? ?? '';
    final budgetOption = lead['budget_option'] as String? ?? '';
    final createdAt = lead['created_at'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (createdAt != null)
                  Text(
                    _formatDate(createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.h),
            if (serviceName != null && serviceName.isNotEmpty) ...[
              Text(
                serviceName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
            ],
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                if (areaName.isNotEmpty) ...[
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      areaName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 3.w),
                ],
                if (budgetOption.isNotEmpty) ...[
                  CustomIconWidget(
                    iconName: 'attach_money',
                    color: AppTheme.successLight,
                    size: 14,
                  ),
                  Flexible(
                    child: Text(
                      budgetOption,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successLight,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDetails,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      side: BorderSide(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Details',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onBuyLead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 1.2.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Buy Lead (\$25)',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
