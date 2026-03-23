import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LeadDetailsSkeletonWidget extends StatelessWidget {
  const LeadDetailsSkeletonWidget({super.key});

  Widget _skeletonBox(ThemeData theme, double height, double? width) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(theme, 32, 120),
          SizedBox(height: 2.h),
          _skeletonBox(theme, 14, double.infinity),
          SizedBox(height: 0.8.h),
          _skeletonBox(theme, 14, double.infinity),
          SizedBox(height: 0.8.h),
          _skeletonBox(theme, 14, 200),
          SizedBox(height: 2.h),
          _skeletonBox(theme, 1, double.infinity),
          SizedBox(height: 2.h),
          for (int i = 0; i < 4; i++) ...[
            Row(
              children: [
                _skeletonBox(theme, 20, 20),
                SizedBox(width: 3.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _skeletonBox(theme, 10, 60),
                    SizedBox(height: 0.4.h),
                    _skeletonBox(theme, 14, 140),
                  ],
                ),
              ],
            ),
            SizedBox(height: 2.h),
          ],
        ],
      ),
    );
  }
}
