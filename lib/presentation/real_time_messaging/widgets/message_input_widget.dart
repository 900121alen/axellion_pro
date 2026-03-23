import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class MessageInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(String type, dynamic data) onAttachment;
  final VoidCallback onTyping;
  final Map<String, dynamic>? replyMessage;
  final VoidCallback? onCancelReply;

  const MessageInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttachment,
    required this.onTyping,
    this.replyMessage,
    this.onCancelReply,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    if (hasText) widget.onTyping();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (!kIsWeb) {
        final permission = source == ImageSource.camera
            ? await Permission.camera.request()
            : await Permission.photos.request();
        if (!permission.isGranted) return;
      }
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (file != null) {
        widget.onAttachment('image', file);
      }
    } catch (_) {}
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 2.h),
                Text('Share Media', style: theme.textTheme.titleMedium),
                SizedBox(height: 2.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _AttachOption(
                      icon: 'camera_alt',
                      label: 'Camera',
                      color: AppTheme.primaryLight,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _AttachOption(
                      icon: 'photo_library',
                      label: 'Gallery',
                      color: AppTheme.secondaryLight,
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyMessage != null) _buildReplyBar(theme, isDark),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
            border: Border(
              top: BorderSide(
                color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _showAttachmentOptions,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 0.8.h, right: 1.w),
                  child: CustomIconWidget(
                    iconName: 'attach_file',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  constraints: BoxConstraints(maxHeight: 12.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.backgroundDark
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 13.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 13.sp,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.2.h,
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 1.w),
              GestureDetector(
                onTap: _hasText ? widget.onSend : null,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _hasText
                        ? AppTheme.primaryLight
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.2,
                          ),
                    shape: BoxShape.circle,
                  ),
                  child: CustomIconWidget(
                    iconName: 'send_rounded',
                    color: _hasText
                        ? Colors.white
                        : theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.5,
                          ),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyBar(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.8.h),
      color: isDark
          ? AppTheme.cardDark
          : AppTheme.primaryLight.withValues(alpha: 0.05),
      child: Row(
        children: [
          Container(width: 3, height: 4.h, color: AppTheme.secondaryLight),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              (widget.replyMessage!['text'] as String?) ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10.sp),
            ),
          ),
          GestureDetector(
            onTap: widget.onCancelReply,
            child: CustomIconWidget(
              iconName: 'close',
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachOption extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: CustomIconWidget(iconName: icon, color: color, size: 26),
          ),
          SizedBox(height: 0.8.h),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}
