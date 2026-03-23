import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _fieldBg = Color(0xFFDDE0E8);

class DetailsSectionWidget extends StatelessWidget {
  final bool isExpanded;
  final TextEditingController additionalRequirementsController;
  final String timelinePreference;
  final void Function(bool) onExpandChanged;
  final void Function(String) onTimelineChanged;

  const DetailsSectionWidget({
    super.key,
    required this.isExpanded,
    required this.additionalRequirementsController,
    required this.timelinePreference,
    required this.onExpandChanged,
    required this.onTimelineChanged,
  });

  static const List<String> _timelines = [
    'ASAP',
    'Within 24 hours',
    'Within a week',
    'Flexible',
    'Specific date',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => onExpandChanged(!isExpanded),
          borderRadius: isExpanded
              ? const BorderRadius.vertical(top: Radius.circular(16))
              : BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _neonBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: CustomIconWidget(
                    iconName: 'add_circle_outline',
                    color: _neonBlue,
                    size: 16,
                  ),
                ),
                SizedBox(width: 3.w),
                const Expanded(
                  child: Text(
                    'Additional Details',
                    style: TextStyle(
                      color: Color(0xFF1A1A2A),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: isExpanded
                      ? 'keyboard_arrow_up'
                      : 'keyboard_arrow_down',
                  color: const Color(0xFF8888AA),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Padding(
            padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 2.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(color: const Color(0xFFD0D3DC)),
                SizedBox(height: 1.h),
                Text(
                  'Additional Requirements',
                  style: TextStyle(
                    color: const Color(0xFF5A5A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.8.h),
                TextFormField(
                  controller: additionalRequirementsController,
                  maxLines: 3,
                  style: const TextStyle(
                    color: Color(0xFF1A1A2A),
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Any specific requirements or preferences...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF8888AA),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: _fieldBg,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.5.h,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: const Color(0xFFD0D3DC)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(color: Color(0xFFD0D3DC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: const BorderSide(
                        color: _neonBlue,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Timeline Preference',
                  style: TextStyle(
                    color: const Color(0xFF5A5A7A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 0.8.h),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _timelines.map((t) {
                    final isSelected = timelinePreference == t;
                    return GestureDetector(
                      onTap: () => onTimelineChanged(t),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 0.7.h,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _neonBlue.withValues(alpha: 0.18)
                              : const Color(0xFFEEEFF4),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: isSelected
                                ? _neonBlue
                                : const Color(0xFFD0D3DC),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          t,
                          style: TextStyle(
                            color: isSelected
                                ? _neonBlue
                                : const Color(0xFF5A5A7A),
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
