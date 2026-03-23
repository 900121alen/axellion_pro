import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RequestDetailsWidget extends StatefulWidget {
  final Map<String, dynamic> requestData;

  const RequestDetailsWidget({super.key, required this.requestData});

  @override
  State<RequestDetailsWidget> createState() => _RequestDetailsWidgetState();
}

class _RequestDetailsWidgetState extends State<RequestDetailsWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachments = (widget.requestData['attachments'] as List?) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'description',
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Request Details',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  CustomIconWidget(
                    iconName: _isExpanded
                        ? 'keyboard_arrow_up'
                        : 'keyboard_arrow_down',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            Divider(height: 1, color: theme.colorScheme.outline),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Description',
                    style: theme.textTheme.labelMedium,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    widget.requestData['description'] as String? ?? '',
                    style: theme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 1.5.h),
                  _DetailRow(
                    icon: 'location_on',
                    label: 'Location',
                    value: widget.requestData['location'] as String? ?? '',
                    context: context,
                  ),
                  SizedBox(height: 1.h),
                  _DetailRow(
                    icon: 'attach_money',
                    label: 'Budget',
                    value: widget.requestData['budget'] as String? ?? '',
                    context: context,
                  ),
                  SizedBox(height: 1.h),
                  _DetailRow(
                    icon: 'calendar_today',
                    label: 'Requested On',
                    value: widget.requestData['requestedOn'] as String? ?? '',
                    context: context,
                  ),
                  if (attachments.isNotEmpty) ...[
                    SizedBox(height: 1.5.h),
                    Text('Attachments', style: theme.textTheme.labelMedium),
                    SizedBox(height: 1.h),
                    SizedBox(
                      height: 12.w,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: attachments.length,
                        separatorBuilder: (_, __) => SizedBox(width: 2.w),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CustomImageWidget(
                              imageUrl: attachments[index] as String,
                              width: 12.w,
                              height: 12.w,
                              fit: BoxFit.cover,
                              semanticLabel:
                                  'Service request attachment ${index + 1}',
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final BuildContext context;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomIconWidget(
          iconName: icon,
          color: theme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: value, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
