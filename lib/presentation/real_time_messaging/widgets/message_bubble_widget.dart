import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isSender;
  final VoidCallback? onLongPress;
  final Map<String, dynamic>? replyMessage;

  const MessageBubbleWidget({
    super.key,
    required this.message,
    required this.isSender,
    this.onLongPress,
    this.replyMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bubbleColor = isSender
        ? AppTheme.primaryLight
        : (isDark ? AppTheme.cardDark : const Color(0xFFEEEEEE));
    final textColor = isSender
        ? Colors.white
        : (isDark ? AppTheme.onSurfaceDark : AppTheme.onSurfaceLight);

    final String type = (message['type'] as String?) ?? 'text';
    final String status = (message['status'] as String?) ?? 'sent';
    final String time = (message['time'] as String?) ?? '';
    final String text = (message['text'] as String?) ?? '';

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 72.w),
          child: Column(
            crossAxisAlignment: isSender
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (replyMessage != null) _buildReplyPreview(context, isDark),
              Container(
                margin: EdgeInsets.symmetric(vertical: 0.4.h),
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isSender ? 16 : 4),
                    bottomRight: Radius.circular(isSender ? 4 : 16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    type == 'image'
                        ? _buildImageMessage(context)
                        : type == 'voice'
                        ? _buildVoiceMessage(context, textColor)
                        : Text(
                            text,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: textColor,
                              fontSize: 13.sp,
                            ),
                          ),
                    SizedBox(height: 0.4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: textColor.withValues(alpha: 0.65),
                            fontSize: 9.sp,
                          ),
                        ),
                        if (isSender) ...[
                          SizedBox(width: 1.w),
                          _buildStatusIcon(status, textColor),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context, bool isDark) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.only(bottom: 0.4.h),
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(color: AppTheme.secondaryLight, width: 3),
        ),
      ),
      child: Text(
        (replyMessage!['text'] as String?) ?? '',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.sp),
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    final String? imageUrl = message['imageUrl'] as String?;
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: imageUrl != null
          ? CustomImageWidget(
              imageUrl: imageUrl,
              width: 55.w,
              height: 22.h,
              fit: BoxFit.cover,
              semanticLabel: 'Shared image in conversation',
            )
          : Container(
              width: 55.w,
              height: 22.h,
              color: Colors.grey.shade300,
              child: const Icon(Icons.broken_image, size: 40),
            ),
    );
  }

  Widget _buildVoiceMessage(BuildContext context, Color textColor) {
    final double duration = (message['duration'] as num?)?.toDouble() ?? 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow_rounded, color: textColor, size: 22),
        SizedBox(width: 1.w),
        Flexible(
          child: Container(
            height: 3.h,
            width: 35.w,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            child: CustomPaint(
              painter: _WaveformPainter(
                color: textColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        SizedBox(width: 1.w),
        Text(
          '${duration.toStringAsFixed(0)}s',
          style: TextStyle(color: textColor, fontSize: 10.sp),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(String status, Color color) {
    IconData icon;
    switch (status) {
      case 'delivered':
        icon = Icons.done_all_rounded;
        break;
      case 'read':
        icon = Icons.done_all_rounded;
        return Icon(icon, size: 14, color: Colors.lightBlueAccent);
      default:
        icon = Icons.done_rounded;
    }
    return Icon(icon, size: 14, color: color.withValues(alpha: 0.7));
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;
  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final heights = [
      0.4,
      0.7,
      1.0,
      0.6,
      0.8,
      0.5,
      0.9,
      0.4,
      0.7,
      0.6,
      0.8,
      1.0,
      0.5,
      0.7,
      0.4,
    ];
    final barWidth = size.width / (heights.length * 2);
    for (int i = 0; i < heights.length; i++) {
      final x = i * barWidth * 2 + barWidth / 2;
      final h = size.height * heights[i];
      final top = (size.height - h) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
