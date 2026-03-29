import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../routes/app_routes.dart';

class ClientRequestDetailsScreen extends StatefulWidget {
  final String requestId;

  const ClientRequestDetailsScreen({super.key, required this.requestId});

  @override
  State<ClientRequestDetailsScreen> createState() =>
      _ClientRequestDetailsScreenState();
}

class _ClientRequestDetailsScreenState
    extends State<ClientRequestDetailsScreen> {
  Map<String, dynamic>? _request;
  bool _isLoading = true;
  String? _error;
  String? _masterName;

  static const Color _bg = Color(0xFFEEEFF4);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _labelColor = Color(0xFF5A5A7A);
  static const Color _valueColor = Color(0xFF1A1A2A);
  static const Color _accentBlue = Color(0xFF5B8ECC);

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('requests')
          .select(
            'category_name, service_name, status, vehicle_info, description, address_full, preferred_date, preferred_time, service_time, media_url, assigned_master_id, created_at',
          )
          .eq('id', widget.requestId)
          .single();

      String? fetchedMasterName;
      final masterId = data['assigned_master_id'] as String?;
      if (masterId != null && masterId.isNotEmpty) {
        try {
          final masterData = await Supabase.instance.client
              .from('users')
              .select('name')
              .eq('id', masterId)
              .maybeSingle();
          fetchedMasterName = masterData?['name'] as String?;
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _request = Map<String, dynamic>.from(data);
          _masterName = fetchedMasterName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load request details';
          _isLoading = false;
        });
      }
    }
  }

  List<String> _parseMediaUrls(dynamic mediaUrl) {
    if (mediaUrl == null) return [];
    if (mediaUrl is List) {
      return mediaUrl
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (mediaUrl is String && mediaUrl.isNotEmpty) {
      try {
        final decoded = jsonDecode(mediaUrl);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {
        return [mediaUrl];
      }
    }
    return [];
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Not specified';
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'assigned':
        return const Color(0xFF5B8ECC);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'declined':
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'in_progress':
        return const Color(0xFF9C27B0);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  String _statusLabel(String? status) {
    if (status == null) return 'Unknown';
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'assigned':
        return 'Assigned';
      case 'completed':
        return 'Completed';
      case 'declined':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      case 'in_progress':
        return 'In Progress';
      case 'searching':
      case 'searching_master':
        return 'Searching';
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Request Details',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2A),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _accentBlue.withValues(alpha: 0.0),
                  _accentBlue.withValues(alpha: 0.5),
                  _accentBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5B8ECC)),
      );
    }
    if (_error != null || _request == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: Color(0xFFF44336),
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Failed to load request details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF5A5A7A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accentBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: Text(
                  'Go Back',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final req = _request!;
    final mediaUrls = _parseMediaUrls(req['media_url']);
    final assignedMasterId = req['assigned_master_id'] as String?;
    final vehicleText = (req['vehicle_info'] as String?)?.isNotEmpty == true
        ? req['vehicle_info'] as String
        : 'Not specified';

    final categoryText = (req['category_name'] as String?)?.isNotEmpty == true
        ? req['category_name'] as String
        : 'Not specified';

    // Compute scheduled date & time value
    final status = req['status'] as String?;
    final bool isScheduled = status == 'scheduled';

    String dateTimeLabel;
    String dateTimeValue;

    if (isScheduled) {
      dateTimeLabel = 'SCHEDULED SERVICE DATE & TIME';
      final serviceTime = req['service_time'] as String?;
      if (serviceTime != null && serviceTime.isNotEmpty) {
        dateTimeValue =
            '${_formatDate(serviceTime)} ${serviceTime.contains('T') ? serviceTime.split('T').last.substring(0, 5) : ''}';
      } else {
        dateTimeValue = 'Not specified';
      }
    } else {
      dateTimeLabel = 'PREFERRED DATE & TIME';
      final prefDate = _formatDate(req['preferred_date'] as String?);
      final prefTime = (req['preferred_time'] as String?)?.isNotEmpty == true
          ? req['preferred_time'] as String
          : 'Flexible';
      final hasDate = prefDate != 'Not specified';
      final hasTime = prefTime != 'Flexible' || hasDate;
      if (hasDate) {
        dateTimeValue = '$prefDate · $prefTime';
      } else if (prefTime != 'Flexible') {
        dateTimeValue = prefTime;
      } else {
        dateTimeValue = 'Not specified';
      }
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoCard(label: 'CATEGORY', value: categoryText),
            const SizedBox(height: 14),
            _InfoCard(
              label: 'SERVICE',
              value: (req['service_name'] as String?) ?? 'Not specified',
            ),
            const SizedBox(height: 14),
            _StatusCard(
              status: req['status'] as String?,
              statusLabel: _statusLabel(req['status'] as String?),
              statusColor: _statusColor(req['status'] as String?),
            ),
            const SizedBox(height: 14),
            _InfoCard(label: 'VEHICLE', value: vehicleText),
            const SizedBox(height: 14),
            _InfoCard(
              label: 'DESCRIPTION',
              value: (req['description'] as String?) ?? 'Not specified',
            ),
            const SizedBox(height: 14),
            _InfoCard(
              label: 'ADDRESS',
              value: (req['address_full'] as String?) ?? 'Not specified',
            ),
            const SizedBox(height: 14),
            _ScheduledDateTimeCard(label: dateTimeLabel, value: dateTimeValue),
            const SizedBox(height: 14),
            _TechnicianCard(
              assignedMasterId: assignedMasterId,
              masterName: _masterName,
            ),
            const SizedBox(height: 14),
            _PhotosCard(mediaUrls: mediaUrls),
            if (assignedMasterId != null) ...[
              const SizedBox(height: 14),
              _OpenChatButton(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.realTimeMessaging,
                    arguments: {
                      'request_id': widget.requestId,
                      'service_title': categoryText,
                    },
                  );
                },
              ),
            ],
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }
}

// ─── Shared card decoration ───────────────────────────────────────────────────

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A7A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A2A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status Card ──────────────────────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  final String? status;
  final String statusLabel;
  final Color statusColor;

  const _StatusCard({
    required this.status,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATUS',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A7A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              statusLabel,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photos Card ──────────────────────────────────────────────────────────────

class _PhotosCard extends StatelessWidget {
  final List<String> mediaUrls;

  const _PhotosCard({required this.mediaUrls});

  void _openFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PHOTOS',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5A5A7A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          if (mediaUrls.isEmpty)
            Text(
              'No media uploaded',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF8888AA),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: mediaUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final url = mediaUrls[index];
                  return GestureDetector(
                    onTap: () => _openFullScreen(context, url),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: CachedNetworkImage(
                        imageUrl: url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFEEEFF4),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF5B8ECC),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFEEEFF4),
                          child: const Icon(
                            Icons.broken_image,
                            color: Color(0xFF8888AA),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Technician Card ──────────────────────────────────────────────────────────

class _ScheduledDateTimeCard extends StatelessWidget {
  final String label;
  final String value;

  const _ScheduledDateTimeCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.calendar_today,
            color: Color(0xFF5B8ECC),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A5A7A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1A2A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TechnicianCard extends StatelessWidget {
  final String? assignedMasterId;
  final String? masterName;

  const _TechnicianCard({
    this.assignedMasterId,
    this.masterName,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSearching =
        assignedMasterId == null || assignedMasterId!.isEmpty;
    final String displayName = isSearching
        ? 'Not assigned'
        : (masterName?.isNotEmpty == true ? masterName! : 'Not assigned');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.person,
            color: Color(0xFF5B8ECC),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TECHNICIAN',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF5A5A7A),
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  displayName,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isSearching ? FontWeight.w500 : FontWeight.w700,
                    color: isSearching
                        ? const Color(0xFF8888AA)
                        : const Color(0xFF1A1A2A),
                    fontStyle: FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Open Chat Button ─────────────────────────────────────────────────────────

class _OpenChatButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: const Icon(
          Icons.chat_bubble_outline,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          'Open Chat',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5B8ECC),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
