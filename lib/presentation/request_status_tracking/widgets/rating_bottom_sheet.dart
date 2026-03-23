import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class RatingBottomSheet extends StatefulWidget {
  final Function(int rating, String comment) onSubmit;

  const RatingBottomSheet({super.key, required this.onSubmit});

  @override
  State<RatingBottomSheet> createState() => _RatingBottomSheetState();
}

class _RatingBottomSheetState extends State<RatingBottomSheet> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text('Rate Your Experience', style: theme.textTheme.titleMedium),
            SizedBox(height: 0.5.h),
            Text(
              'How was the service provided?',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: 2.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: CustomIconWidget(
                      iconName: index < _selectedRating
                          ? 'star'
                          : 'star_border',
                      color: AppTheme.accentColor,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedRating > 0
                    ? () {
                        widget.onSubmit(
                          _selectedRating,
                          _commentController.text,
                        );
                        Navigator.pop(context);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
                child: const Text('Submit Review'),
              ),
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }
}
