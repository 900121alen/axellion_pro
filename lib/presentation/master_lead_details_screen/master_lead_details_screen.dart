import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../../theme/app_theme.dart';

class MasterLeadDetailsScreen extends StatelessWidget {
  const MasterLeadDetailsScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF9E9E9E);
      case 'searching':
      case 'searching_master':
        return const Color(0xFFFF9800);
      case 'assigned':
        return const Color(0xFF2196F3);
      case 'answered':
      case 'in_progress':
        return const Color(0xFF9C27B0);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
      case 'archived':
        return const Color(0xFFF44336);
      case 'relisted':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'searching':
      case 'searching_master':
        return 'Searching';
      case 'assigned':
        return 'Assigned';
      case 'answered':
        return 'Answered';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'archived':
        return 'Archived';
      case 'relisted':
        return 'Relisted';
      case 'pending':
        return 'Pending';
      default:
        return status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : status;
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return '';
    }
  }

  String _formatServiceTime(String? serviceTime) {
    if (serviceTime == null || serviceTime.isEmpty) return 'Not specified';
    try {
      final dt = DateTime.parse(serviceTime).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      final date = '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      return '$date • $hour:$minute $period';
    } catch (_) {
      return serviceTime;
    }
  }

  void _openChat(BuildContext context, Map<String, dynamic> lead) {
    final requestId = lead['id'] as String?;
    final category = lead['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'Service Request';
    final clientId = lead['client_id'] as String?;

    Navigator.pushNamed(
      context,
      '/real-time-messaging',
      arguments: {
        'request_id': requestId,
        'service_title': categoryName,
        'other_user_id': clientId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lead =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
        {};

    final category = lead['categories'] as Map<String, dynamic>?;
    final categoryNameFromJoin = category?['name'] as String?;
    final categoryNameDirect = lead['category_name'] as String?;
    final serviceName = lead['service_name'] as String?;
    final categoryName =
        categoryNameDirect ?? categoryNameFromJoin ?? 'General';
    final description = lead['description'] as String? ?? '';
    final status = lead['status'] as String? ?? 'assigned';
    final createdAt = lead['created_at'] as String?;
    final areaName = lead['area_name'] as String?;
    final addressFull = lead['address_full'] as String?;
    final clientName = lead['client_name'] as String?;
    final serviceTime = lead['service_time'] as String?;

    final badgeColor = _statusColor(status);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Lead Details',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : const Color(0xFF111111),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card: service name + status badge
                    _DetailCard(
                      isDark: isDark,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (serviceName != null &&
                                    serviceName.isNotEmpty) ...[
                                  Text(
                                    categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? Colors.white54
                                          : const Color(0xFF8888AA),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    serviceName,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF111111),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: badgeColor.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Description
                    if (description.isNotEmpty)
                      _DetailCard(
                        isDark: isDark,
                        child: _LabelValue(
                          label: 'Description',
                          value: description,
                          isDark: isDark,
                          maxLines: null,
                        ),
                      ),

                    if (description.isNotEmpty) const SizedBox(height: 12),

                    // Client section (replaces Master section)
                    _DetailCard(
                      isDark: isDark,
                      child: _LabelValue(
                        label: 'Client',
                        value: clientName ?? 'Unknown client',
                        isDark: isDark,
                        valueColor: clientName != null
                            ? const Color(0xFF2196F3)
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Address
                    if (areaName != null || addressFull != null)
                      _DetailCard(
                        isDark: isDark,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addressFull != null && addressFull.isNotEmpty)
                              _LabelValue(
                                label: 'Address',
                                value: addressFull,
                                isDark: isDark,
                                maxLines: null,
                              )
                            else if (areaName != null && areaName.isNotEmpty)
                              _LabelValue(
                                label: 'Address',
                                value: areaName,
                                isDark: isDark,
                                maxLines: null,
                              ),
                          ],
                        ),
                      ),

                    if (areaName != null || addressFull != null)
                      const SizedBox(height: 12),

                    // Request Date
                    if (createdAt != null)
                      _DetailCard(
                        isDark: isDark,
                        child: _LabelValue(
                          label: 'Request Date',
                          value: _formatDate(createdAt),
                          isDark: isDark,
                        ),
                      ),

                    if (createdAt != null) const SizedBox(height: 12),

                    // Preferred Service Time
                    _DetailCard(
                      isDark: isDark,
                      child: _LabelValue(
                        label: 'Preferred Service Time',
                        value: _formatServiceTime(serviceTime),
                        isDark: isDark,
                        valueColor: serviceTime == null
                            ? (isDark
                                  ? Colors.white54
                                  : const Color(0xFFAAAAAA))
                            : null,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Media section
                    _DetailCard(
                      isDark: isDark,
                      child: _MediaSection(
                        isDark: isDark,
                        mediaUrls: _parseMediaUrls(lead['media_url']),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom action button
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context, lead),
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text(
                    'Open Chat',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
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

class _DetailCard extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const _DetailCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _LabelValue extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final int? maxLines;

  const _LabelValue({
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color:
                valueColor ?? (isDark ? Colors.white : const Color(0xFF111111)),
          ),
          maxLines: maxLines,
          overflow: maxLines != null ? TextOverflow.ellipsis : null,
        ),
      ],
    );
  }
}

class _MediaSection extends StatelessWidget {
  final bool isDark;
  final List<String>? mediaUrls;

  const _MediaSection({required this.isDark, this.mediaUrls});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMedia = mediaUrls != null && mediaUrls!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Media',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        if (!hasMedia)
          Text(
            'No media uploaded',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFFAAAAAA),
            ),
          )
        else
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: mediaUrls!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final url = mediaUrls![index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _FullScreenImagePage(imageUrl: url),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.0),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFEEEEEE),
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: isDark ? Colors.white38 : Colors.black26,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _FullScreenImagePage extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImagePage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

List<String> _parseMediaUrls(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } catch (_) {}
  }
  return [];
}
