import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class AssignedMasterWidget extends StatelessWidget {
  final Map<String, dynamic> masterData;
  final VoidCallback onContact;

  const AssignedMasterWidget({
    super.key,
    required this.masterData,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rating = (masterData['rating'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'engineering',
                color: theme.colorScheme.primary,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text('Assigned Master', style: theme.textTheme.titleSmall),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: CustomImageWidget(
                  imageUrl: masterData['avatar'] as String? ?? '',
                  width: 14.w,
                  height: 14.w,
                  fit: BoxFit.cover,
                  semanticLabel:
                      'Profile photo of ${masterData['name'] as String? ?? 'master'}',
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      masterData['name'] as String? ?? '',
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return CustomIconWidget(
                            iconName: i < rating.floor()
                                ? 'star'
                                : (i < rating ? 'star_half' : 'star_border'),
                            color: AppTheme.accentColor,
                            size: 14,
                          );
                        }),
                        SizedBox(width: 1.w),
                        Text(
                          rating > 0 ? rating.toStringAsFixed(1) : '',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
