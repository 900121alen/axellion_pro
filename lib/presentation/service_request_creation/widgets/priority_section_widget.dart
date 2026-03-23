import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

const Color _neonBlue = Color(0xFF3A8BFF);

class PrioritySectionWidget extends StatelessWidget {
  final String selectedPriority;
  final void Function(String) onPriorityChanged;

  const PrioritySectionWidget({
    super.key,
    required this.selectedPriority,
    required this.onPriorityChanged,
  });

  static const List<Map<String, dynamic>> _priorities = [
    {'label': 'Low', 'icon': 'arrow_downward', 'color': 0xFF10B981},
    {'label': 'Normal', 'icon': 'remove', 'color': 0xFF3A8BFF},
    {'label': 'High', 'icon': 'arrow_upward', 'color': 0xFFF4A261},
    {'label': 'Urgent', 'icon': 'priority_high', 'color': 0xFFEF4444},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: _neonBlue,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            SizedBox(width: 2.w),
            const Text(
              'Priority Level',
              style: TextStyle(
                color: Color(0xFF1A1A2A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _priorities.map((p) {
            final label = p['label'] as String;
            final isSelected = selectedPriority == label;
            final color = Color(p['color'] as int);
            return GestureDetector(
              onTap: () => onPriorityChanged(label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 3.5.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.18)
                      : const Color(0xFFEEEFF4),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFD0D3DC),
                    width: isSelected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10.0),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: p['icon'] as String,
                      color: isSelected ? color : const Color(0xFF8888AA),
                      size: 16,
                    ),
                    SizedBox(width: 1.5.w),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? color : const Color(0xFF5A5A7A),
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
