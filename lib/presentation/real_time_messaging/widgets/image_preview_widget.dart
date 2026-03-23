import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ImagePreviewWidget extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onClose;

  const ImagePreviewWidget({
    super.key,
    required this.imageUrl,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CustomImageWidget(
                  imageUrl: imageUrl,
                  width: 90.w,
                  height: 70.h,
                  fit: BoxFit.contain,
                  semanticLabel: 'Full screen image preview',
                ),
              ),
            ),
            Positioned(
              top: 4.h,
              right: 4.w,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'close',
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
