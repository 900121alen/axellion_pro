import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class NotificationBannerWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const NotificationBannerWidget({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: Row(
          children: [
            CustomIconWidget(
              iconName: 'notifications_active',
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Text(
                widget.message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
            GestureDetector(
              onTap: widget.onDismiss,
              child: CustomIconWidget(
                iconName: 'close',
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
