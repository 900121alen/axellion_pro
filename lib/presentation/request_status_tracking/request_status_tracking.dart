import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/action_buttons_widget.dart';
import './widgets/assigned_master_widget.dart';
import './widgets/offline_banner_widget.dart';
import './widgets/rating_bottom_sheet.dart';
import './widgets/status_timeline_widget.dart';

class RequestStatusTracking extends StatefulWidget {
  final String? requestId;
  const RequestStatusTracking({super.key, this.requestId});

  @override
  State<RequestStatusTracking> createState() => _RequestStatusTrackingState();
}

class _RequestStatusTrackingState extends State<RequestStatusTracking>
    with SingleTickerProviderStateMixin {
  bool _isOnline = true;
  bool _isRefreshing = false;
  bool _isLoading = true;

  late AnimationController _progressAnimController;
  late Animation<double> _progressAnim;

  String _currentStatus = 'searching';
  final String _lastUpdated = '';

  // Request data from Supabase
  String _serviceName = '';
  String _scheduleStart = '';
  String _scheduleEnd = '';
  Map<String, dynamic> _masterData = {};

  // Realtime subscription
  RealtimeChannel? _realtimeChannel;

  List<Map<String, dynamic>> get _statusSteps {
    final isCancelled = _currentStatus.toLowerCase() == 'cancelled';
    if (isCancelled) {
      return [
        {
          'title': 'Searching',
          'description': 'Looking for an available master near you',
          'timestamp': '',
          'status': 'completed',
        },
        {
          'title': 'Assigned',
          'description': 'A master has accepted your request',
          'timestamp': '',
          'status': 'completed',
        },
        {
          'title': 'Scheduled',
          'description': 'Your service time has been scheduled',
          'timestamp': '',
          'status': 'completed',
        },
        {
          'title': 'Cancelled',
          'description': 'This request has been cancelled',
          'timestamp': '',
          'status': 'cancelled',
        },
      ];
    }
    return [
      {
        'title': 'Searching',
        'description': 'Looking for an available master near you',
        'timestamp': '',
        'status': _stepStatus(0),
      },
      {
        'title': 'Assigned',
        'description': 'A master has accepted your request',
        'timestamp': '',
        'status': _stepStatus(1),
      },
      {
        'title': 'Scheduled',
        'description': 'Your service time has been scheduled',
        'timestamp': '',
        'status': _stepStatus(2),
      },
      {
        'title': 'Completed',
        'description':
            'Service will be marked completed after the work is finished',
        'timestamp': '',
        'status': _stepStatus(3),
      },
    ];
  }

  int get _activeStepIndex {
    switch (_currentStatus.toLowerCase()) {
      case 'searching':
      case 'searching_master':
        return 0;
      case 'assigned':
        return 1;
      case 'scheduled':
        return 2;
      case 'completed':
        return 3;
      case 'cancelled':
        return 3; // points to the Cancelled step (last)
      default:
        return 0;
    }
  }

  String _stepStatus(int stepIndex) {
    final active = _activeStepIndex;
    if (stepIndex < active) return 'completed';
    if (stepIndex == active) return 'active';
    return 'pending';
  }

  bool get _showMaster =>
      _currentStatus == 'assigned' ||
      _currentStatus == 'scheduled' ||
      _currentStatus == 'completed';

  bool get _isCancelVisible =>
      _currentStatus == 'searching' ||
      _currentStatus == 'searching_master' ||
      _currentStatus == 'assigned' ||
      _currentStatus == 'scheduled';

  bool get _isCancelDisabled {
    if (_currentStatus != 'scheduled') return false;
    if (_scheduleStart.isEmpty) return false;
    try {
      final scheduleStart = DateTime.parse(_scheduleStart).toLocal();
      final twoHoursBefore = scheduleStart.subtract(const Duration(hours: 2));
      return DateTime.now().isAfter(twoHoursBefore) ||
          DateTime.now().isAtSameMomentAs(twoHoursBefore);
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _progressAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _progressAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressAnimController, curve: Curves.easeInOut),
    );
    _checkConnectivity();
    _listenConnectivity();
    _loadRequestData();
    _subscribeRealtime();
  }

  void _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      if (mounted) {
        setState(() {
          _isOnline = result != ConnectivityResult.none;
        });
      }
    });
  }

  void _subscribeRealtime() {
    if (widget.requestId == null) return;
    _realtimeChannel = Supabase.instance.client
        .channel('request_status_${widget.requestId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.requestId!,
          ),
          callback: (payload) {
            final newRow = payload.newRecord;
            if (newRow.isEmpty) return;
            final status = (newRow['status'] as String? ?? _currentStatus)
                .toLowerCase();
            final serviceName =
                newRow['service_name'] as String? ?? _serviceName;
            final serviceTime =
                newRow['service_time'] as String? ?? _scheduleStart;
            final serviceTimeEnd =
                newRow['service_time_end'] as String? ?? _scheduleEnd;
            if (mounted) {
              setState(() {
                _currentStatus = status;
                _serviceName = serviceName;
                _scheduleStart = serviceTime;
                _scheduleEnd = serviceTimeEnd;
              });
            }
          },
        )
        .subscribe();
  }

  Future<void> _loadRequestData() async {
    if (widget.requestId == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('requests')
          .select(
            'id, status, service_name, service_time, service_time_end, assigned_master_id',
          )
          .eq('id', widget.requestId!)
          .maybeSingle();

      if (response == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final status = (response['status'] as String? ?? 'searching')
          .toLowerCase();
      final serviceName = response['service_name'] as String? ?? '';
      final serviceTime = response['service_time'] as String? ?? '';
      final serviceTimeEnd = response['service_time_end'] as String? ?? '';
      final assignedMasterId = response['assigned_master_id'] as String?;

      Map<String, dynamic> masterData = {};
      if (assignedMasterId != null) {
        try {
          final masterResponse = await Supabase.instance.client
              .from('users')
              .select('id, name, avatar_url, rating')
              .eq('id', assignedMasterId)
              .maybeSingle();
          if (masterResponse != null) {
            masterData = {
              'name': masterResponse['name'] as String? ?? 'Master',
              'avatar': masterResponse['avatar_url'] as String? ?? '',
              'rating': (masterResponse['rating'] as num?)?.toDouble() ?? 0.0,
            };
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _currentStatus = status;
          _serviceName = serviceName;
          _scheduleStart = serviceTime;
          _scheduleEnd = serviceTimeEnd;
          _masterData = masterData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _progressAnimController.dispose();
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (!kIsWeb) HapticFeedback.mediumImpact();
    setState(() => _isRefreshing = true);
    await _loadRequestData();
    if (mounted) setState(() => _isRefreshing = false);
  }

  void _showRatingSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => RatingBottomSheet(
        onSubmit: (rating, comment) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Thank you! You rated $rating stars.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _handleCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text(
          'Are you sure you want to cancel this service request?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Request cancelled successfully.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorLight),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request?'),
        content: const Text('Are you sure you want to cancel this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Request'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
            ),
            child: const Text('Cancel Service'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .from('requests')
          .update({'status': 'cancelled'})
          .eq('id', widget.requestId!);

      // Re-fetch from DB to get the authoritative status
      await _loadRequestData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request cancelled successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to cancel request. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleContact() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/real-time-messaging');
  }

  void _handleMarkComplete() {
    if (!kIsWeb) HapticFeedback.heavyImpact();
    _showRatingSheet();
  }

  void _handleRelist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Request relisted successfully. Searching for masters...',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _displayStatus() {
    switch (_currentStatus.toLowerCase()) {
      case 'searching':
      case 'searching_master':
        return 'Searching';
      case 'assigned':
        return 'Assigned';
      case 'scheduled':
        return 'Service Scheduled';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Service Scheduled';
    }
  }

  String _formatScheduleTime(String isoStart, String isoEnd) {
    try {
      final start = DateTime.parse(isoStart).toLocal();
      final end = isoEnd.isNotEmpty ? DateTime.parse(isoEnd).toLocal() : null;
      final datePart = DateFormat('MMM d').format(start);
      final startTime = DateFormat('h:mm a').format(start);
      if (end != null) {
        final endTime = DateFormat('h:mm a').format(end);
        return '$datePart • $startTime – $endTime';
      }
      return '$datePart • $startTime';
    } catch (_) {
      return isoStart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Request Status',
        showBackButton: true,
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isOnline) OfflineBannerWidget(lastUpdated: _lastUpdated),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: theme.colorScheme.primary,
              child: SafeArea(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 2.h,
                          horizontal: 4.w,
                        ),
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusHeader(theme),
                              SizedBox(height: 2.h),
                              _buildTimelineSection(theme),
                              if (_showMaster && _masterData.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                AssignedMasterWidget(
                                  masterData: _masterData,
                                  onContact: _handleContact,
                                ),
                              ],
                              SizedBox(height: 2.h),
                              if (_isCancelVisible) _buildCancelButton(theme),
                              SizedBox(height: 2.h),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ),
          ActionButtonsWidget(
            currentStatus: _currentStatus,
            onCancel: _handleCancel,
            onContact: _handleContact,
            onMarkComplete: _handleMarkComplete,
            onRelist: _handleRelist,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(ThemeData theme) {
    final Color statusColor = _currentStatus == 'completed'
        ? AppTheme.successLight
        : _currentStatus == 'cancelled'
        ? AppTheme.errorLight
        : theme.colorScheme.primary;

    const IconData headerIcon = Icons.event_available;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withValues(alpha: 0.12),
            statusColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _progressAnim,
            builder: (context, child) {
              return Container(
                width: 16.w,
                height: 16.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: statusColor.withValues(
                      alpha: 0.3 + 0.4 * _progressAnim.value,
                    ),
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 11.w,
                    height: 11.w,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(headerIcon, color: statusColor, size: 22),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayStatus(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_serviceName.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    _serviceName,
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (_scheduleStart.isNotEmpty) ...[
                  SizedBox(height: 0.3.h),
                  Text(
                    'Scheduled: ${_formatScheduleTime(_scheduleStart, _scheduleEnd)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'timeline',
                color: theme.colorScheme.primary,
                size: 18,
              ),
              SizedBox(width: 2.w),
              Text('Status Timeline', style: theme.textTheme.titleSmall),
            ],
          ),
          SizedBox(height: 2.h),
          StatusTimelineWidget(
            statusSteps: _statusSteps,
            currentStepIndex: _activeStepIndex,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(ThemeData theme) {
    final bool disabled = _isCancelDisabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: disabled ? null : _cancelRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: disabled
                  ? const Color(0xFFE53935).withValues(alpha: 0.4)
                  : const Color(0xFFE53935),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(
                0xFFE53935,
              ).withValues(alpha: 0.4),
              disabledForegroundColor: Colors.white70,
              padding: EdgeInsets.symmetric(vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: disabled ? 0 : 2,
            ),
            child: Text(
              'Cancel Request',
              style: theme.textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (disabled) ...[
          SizedBox(height: 0.8.h),
          Text(
            'Cancellation is not available less than 2 hours before the scheduled service.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFFE53935),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
