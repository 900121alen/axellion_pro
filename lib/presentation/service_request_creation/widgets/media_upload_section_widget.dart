import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_image_widget.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _fieldBg = Color(0xFFDDE0E8);

class MediaUploadSectionWidget extends StatefulWidget {
  final List<XFile> mediaFiles;
  final void Function(List<XFile>) onMediaChanged;

  const MediaUploadSectionWidget({
    super.key,
    required this.mediaFiles,
    required this.onMediaChanged,
  });

  @override
  State<MediaUploadSectionWidget> createState() =>
      _MediaUploadSectionWidgetState();
}

class _MediaUploadSectionWidgetState extends State<MediaUploadSectionWidget> {
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<bool> _requestPermission(ImageSource source) async {
    if (kIsWeb) return true;
    final permission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;
    final status = await permission.request();
    return status.isGranted;
  }

  Future<void> _pickMedia(ImageSource source) async {
    final granted = await _requestPermission(source);
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable in settings.'),
          ),
        );
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (source == ImageSource.camera) {
        final file = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (file != null) {
          final updated = [...widget.mediaFiles, file];
          widget.onMediaChanged(updated);
        }
      } else {
        final files = await _picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );
        if (files.isNotEmpty) {
          final updated = [...widget.mediaFiles, ...files];
          widget.onMediaChanged(updated.take(10).toList());
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not pick media. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F6FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD0D3DC).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(Icons.camera_alt, color: _neonBlue, size: 20),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Color(0xFF1A1A2A), fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: _neonBlue,
                  size: 20,
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Color(0xFF1A1A2A), fontSize: 14),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickMedia(ImageSource.gallery);
              },
            ),
            SizedBox(height: 1.h),
          ],
        ),
      ),
    );
  }

  void _removeMedia(int index) {
    final updated = [...widget.mediaFiles];
    updated.removeAt(index);
    widget.onMediaChanged(updated);
  }

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
              'Media',
              style: TextStyle(
                color: Color(0xFF1A1A2A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 2.w),
            Text(
              '(${widget.mediaFiles.length}/10)',
              style: TextStyle(color: const Color(0xFF8888AA), fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        SizedBox(
          height: 12.h,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (widget.mediaFiles.length < 10)
                GestureDetector(
                  onTap: _showPickerOptions,
                  child: Container(
                    width: 12.h,
                    height: 12.h,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _fieldBg,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: _neonBlue.withValues(alpha: 0.3),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _neonBlue,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _neonBlue.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate,
                                  color: _neonBlue,
                                  size: 22,
                                ),
                              ),
                              SizedBox(height: 0.5.h),
                              Text(
                                'Add',
                                style: TextStyle(
                                  color: const Color(0xFF5A5A7A),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ...widget.mediaFiles.asMap().entries.map((entry) {
                final i = entry.key;
                final file = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 12.h,
                      height: 12.h,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: _fieldBg,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: CustomImageWidget(
                          imageUrl: file.path,
                          width: 12.h,
                          height: 12.h,
                          fit: BoxFit.cover,
                          semanticLabel: 'Uploaded media file ${i + 1}',
                        ),
                      ),
                    ),
                    Positioned(
                      top: 2,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => _removeMedia(i),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
