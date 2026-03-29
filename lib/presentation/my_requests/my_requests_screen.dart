import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../client_request_details/client_request_details_screen.dart';
import '../request_status_tracking/request_status_tracking.dart';

const Color _neonBlue = Color(0xFF5B8ECC);
const Color _darkBg = Color(0xFFEEEFF4);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _sectionBg = Color(0xFFF5F6FA);
const Color _borderColor = Color(0xFFD0D3DC);

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  String? _error;

  RealtimeChannel? _realtimeChannel;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    _realtimeChannel = Supabase.instance.client
        .channel('my_requests_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'requests',
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            final updatedId = newRow['id'] as String?;
            if (updatedId == null) return;
            if (mounted) {
              setState(() {
                final idx = _requests.indexWhere((r) => r['id'] == updatedId);
                if (idx != -1) {
                  _requests[idx] = {..._requests[idx], ...newRow};
                }
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _fetchRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Not authenticated. Please log in again.';
          _isLoading = false;
        });
        return;
      }
      final response = await Supabase.instance.client
          .from('requests')
          .select(
            'id, description, status, created_at, area_name, address_full, assigned_master_id, service_time, service_time_end, category_name, service_name, preferred_date, preferred_time, categories(name)',
          )
          .eq('client_id', userId)
          .order('created_at', ascending: false);

      final requests = List<Map<String, dynamic>>.from(response);

      // Fetch master names for assigned requests
      final masterIds = requests
          .where((r) => r['assigned_master_id'] != null)
          .map((r) => r['assigned_master_id'] as String)
          .toSet()
          .toList();

      Map<String, String> masterNames = {};
      if (masterIds.isNotEmpty) {
        try {
          final mastersResponse = await Supabase.instance.client
              .from('users')
              .select('id, name')
              .inFilter('id', masterIds);
          for (final m in mastersResponse) {
            final id = m['id'] as String?;
            final name = m['name'] as String?;
            if (id != null && name != null) {
              masterNames[id] = name;
            }
          }
        } catch (_) {}
      }

      // Attach master name to each request
      final enriched = requests.map((r) {
        final mid = r['assigned_master_id'] as String?;
        return {...r, 'master_name': mid != null ? masterNames[mid] : null};
      }).toList();

      if (mounted) {
        setState(() {
          _requests = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests. Pull to refresh.';
          _isLoading = false;
        });
      }
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
      return '${months[dt.month - 1]} ${dt.day}';
    } catch (_) {
      return '';
    }
  }

  String _formatServiceTime(String? serviceTime, String? serviceTimeEnd) {
    if (serviceTime == null || serviceTime.isEmpty) return '';
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
      final date = '${months[dt.month - 1]} ${dt.day}';
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour < 12 ? 'AM' : 'PM';
      final startTime = '$hour:$minute $period';

      if (serviceTimeEnd != null && serviceTimeEnd.isNotEmpty) {
        try {
          final dtEnd = DateTime.parse(serviceTimeEnd).toLocal();
          final hourEnd = dtEnd.hour % 12 == 0 ? 12 : dtEnd.hour % 12;
          final minuteEnd = dtEnd.minute.toString().padLeft(2, '0');
          final periodEnd = dtEnd.hour < 12 ? 'AM' : 'PM';
          final endTime = '$hourEnd:$minuteEnd $periodEnd';
          return 'Scheduled: $date • $startTime – $endTime';
        } catch (_) {}
      }
      return 'Scheduled: $date • $startTime';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A2A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Requests',
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
                  _neonBlue.withValues(alpha: 0.0),
                  _neonBlue.withValues(alpha: 0.5),
                  _neonBlue.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 2.h),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your activity',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF8888AA),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'My Requests',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _neonBlue.withValues(alpha: 0.25),
                _neonBlue.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: _neonBlue.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _neonBlue.withValues(alpha: 0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: CustomIconWidget(
              iconName: 'assignment',
              color: _neonBlue,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildSkeleton();
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFF44336).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF44336).withValues(alpha: 0.3),
                ),
              ),
              child: const Center(
                child: CustomIconWidget(
                  iconName: 'error_outline',
                  color: Color(0xFFF44336),
                  size: 36,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              _error!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF5A5A7A),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _fetchRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: _neonBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _neonBlue.withValues(alpha: 0.15),
                    _neonBlue.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: _neonBlue.withValues(alpha: 0.25)),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'assignment_outlined',
                  color: _neonBlue.withValues(alpha: 0.7),
                  size: 38,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'No requests yet',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A2A),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Your service requests will appear here.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF8888AA),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchRequests,
      color: _neonBlue,
      backgroundColor: _cardBg,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _requests.length,
        separatorBuilder: (_, __) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _RequestCard(
            request: request,
            formatDate: _formatDate,
            formatServiceTime: _formatServiceTime,
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 2.h),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_cardBg, _sectionBg],
            ),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: _borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
              BoxShadow(
                color: _neonBlue.withValues(alpha: 0.04),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 36,
                    width: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D3DC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D3DC),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 22,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D3DC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D3DC),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(height: 0.5.h),
              Container(
                height: 12,
                width: 160,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D3DC),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final String Function(String?) formatDate;
  final String Function(String?, String?) formatServiceTime;

  const _RequestCard({
    required this.request,
    required this.formatDate,
    required this.formatServiceTime,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF9E9E9E);
      case 'searching':
      case 'searching_master':
        return const Color(0xFFFF9800);
      case 'assigned':
        return const Color(0xFF5B8ECC);
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
      case 'scheduled':
        return const Color(0xFFFFC107);
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
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  // Per-status accent color for the left border indicator
  Color _accentColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'assigned':
        return const Color(0xFF5B8ECC);
      case 'in_progress':
      case 'answered':
        return const Color(0xFF9C27B0);
      case 'searching':
      case 'searching_master':
      case 'relisted':
        return const Color(0xFFFF9800);
      case 'cancelled':
      case 'archived':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = request['categories'] as Map<String, dynamic>?;
    final categoryNameFromJoin = category?['name'] as String?;
    final categoryNameDirect = request['category_name'] as String?;
    final serviceName = request['service_name'] as String?;
    // Use direct category_name if available, fall back to join result
    final categoryName =
        categoryNameDirect ?? categoryNameFromJoin ?? 'General';
    // Build display title: "Category • Service" or just "Category"
    final displayTitle = (serviceName != null && serviceName.isNotEmpty)
        ? '$categoryName • $serviceName'
        : categoryName;
    final description = request['description'] as String? ?? '';
    final status = request['status'] as String? ?? 'searching';
    final createdAt = request['created_at'] as String?;
    final assignedMasterId = request['assigned_master_id'] as String?;
    final masterName = request['master_name'] as String?;
    final requestId = request['id'] as String?;
    final serviceTime = request['service_time'] as String?;
    final serviceTimeEnd = request['service_time_end'] as String?;
    final preferredDate = request['preferred_date'] as String?;
    final preferredTime = request['preferred_time'] as String?;

    // Compute merged date/time label
    String scheduledDateTime = '';
    String dateTimeLabel = '';
    if (status == 'scheduled') {
      dateTimeLabel = 'Scheduled service date and time';
      scheduledDateTime = formatServiceTime(serviceTime, serviceTimeEnd);
    } else {
      dateTimeLabel = 'Preferred service date and time';
      // Combine preferred_date + preferred_time strictly
      final datePart = preferredDate != null && preferredDate.isNotEmpty
          ? preferredDate
          : '';
      final timePart = preferredTime != null && preferredTime.isNotEmpty
          ? preferredTime
          : '';
      if (datePart.isNotEmpty && timePart.isNotEmpty) {
        scheduledDateTime = '$datePart • $timePart';
      } else if (datePart.isNotEmpty) {
        scheduledDateTime = datePart;
      } else if (timePart.isNotEmpty) {
        scheduledDateTime = timePart;
      }
    }

    final badgeColor = _statusColor(status);
    final accent = _accentColor(status);
    final isAssigned = assignedMasterId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cardBg, _sectionBg],
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left accent bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, accent.withValues(alpha: 0.3)],
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: Category name + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
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
                                      color: const Color(0xFF8888AA),
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    serviceName,
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2A),
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ] else ...[
                                  Text(
                                    categoryName,
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2A),
                                      letterSpacing: 0.2,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (requestId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RequestStatusTracking(
                                      requestId: requestId,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: badgeColor.withValues(alpha: 0.35),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.timeline,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _statusLabel(status),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Row 2: Description
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF5A5A7A),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 10),

                      // Row 3: Service Date & Time (combined)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 15,
                            color: Color(0xFF5B8ECC),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$dateTimeLabel:',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF5A5A7A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  scheduledDateTime.isNotEmpty
                                      ? scheduledDateTime
                                      : 'Not specified',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1A1A2A),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.visible,
                                  softWrap: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Row 4: Technician
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person,
                            size: 15,
                            color: Color(0xFF7B6FAD),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Technician: ',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5A5A7A),
                            ),
                          ),
                          Expanded(
                            child:
                                assignedMasterId != null && masterName != null
                                    ? Text(
                                        masterName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF7B6FAD),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      )
                                    : Text(
                                        'Searching for technician...',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFFF9800),
                                          fontStyle: FontStyle.italic,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                          ),
                        ],
                      ),

                      // Row 5: Action buttons
                      const SizedBox(height: 12),
                      if (status == 'cancelled') ...[
                        // Cancelled banner
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFF44336).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.0),
                            border: Border.all(
                              color: const Color(0xFFF44336)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cancel_outlined,
                                size: 16,
                                color: Color(0xFFF44336),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'This request has been cancelled',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFFF44336),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isAssigned && requestId != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pushNamed(
                                    AppRoutes.realTimeMessaging,
                                    arguments: {
                                      'request_id': requestId,
                                      'service_title': displayTitle,
                                    },
                                  );
                                },
                                icon: const CustomIconWidget(
                                  iconName: 'chat_bubble_outline',
                                  color: Colors.white,
                                  size: 14,
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
                                  backgroundColor: _neonBlue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ClientRequestDetailsScreen(
                                        requestId: requestId,
                                      ),
                                    ),
                                  );
                                },
                                icon: CustomIconWidget(
                                  iconName: 'info_outline',
                                  color: _neonBlue,
                                  size: 14,
                                ),
                                label: Text(
                                  'Details',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: _neonBlue,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  side: BorderSide(color: _neonBlue),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              if (requestId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ClientRequestDetailsScreen(
                                      requestId: requestId,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: CustomIconWidget(
                              iconName: 'info_outline',
                              color: _neonBlue,
                              size: 14,
                            ),
                            label: Text(
                              'Details',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _neonBlue,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              side: BorderSide(color: _neonBlue),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
