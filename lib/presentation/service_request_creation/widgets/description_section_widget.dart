import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _fieldBg = Color(0xFFDDE0E8);

class DescriptionSectionWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? error;
  final void Function(String) onChanged;

  const DescriptionSectionWidget({
    super.key,
    required this.controller,
    required this.error,
    required this.onChanged,
  });

  @override
  State<DescriptionSectionWidget> createState() =>
      _DescriptionSectionWidgetState();
}

class _DescriptionSectionWidgetState extends State<DescriptionSectionWidget> {
  static const int _maxChars = 500;

  static const List<String> _suggestions = [
    'I need help with...',
    'There is a problem with...',
    'I would like to repair...',
    'Something is damaged and needs fixing...',
  ];

  @override
  Widget build(BuildContext context) {
    final charCount = widget.controller.text.length;
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
              'Description',
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
        TextFormField(
          controller: widget.controller,
          maxLines: 5,
          maxLength: _maxChars,
          style: const TextStyle(color: Color(0xFF1A1A2A), fontSize: 14),
          onChanged: (v) {
            setState(() {});
            widget.onChanged(v);
          },
          decoration: InputDecoration(
            hintText: 'Describe the service you need in detail...',
            hintStyle: TextStyle(color: const Color(0xFF8888AA), fontSize: 13),
            errorText: widget.error,
            errorStyle: const TextStyle(color: Color(0xFFEF4444)),
            counterText: '$charCount/$_maxChars',
            counterStyle: TextStyle(
              color: const Color(0xFF8888AA),
              fontSize: 11,
            ),
            alignLabelWithHint: true,
            filled: true,
            fillColor: _fieldBg,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: 1.5.h,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFD0D3DC)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: _neonBlue, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFFEF4444),
                width: 1.5,
              ),
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          'Quick suggestions:',
          style: TextStyle(color: const Color(0xFF5A5A7A), fontSize: 12),
        ),
        SizedBox(height: 0.5.h),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _suggestions.map((s) {
            return GestureDetector(
              onTap: () {
                final newText = s;
                widget.controller.text = newText;
                widget.controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: newText.length),
                );
                setState(() {});
                widget.onChanged(newText);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
                decoration: BoxDecoration(
                  color: _neonBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    color: _neonBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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
