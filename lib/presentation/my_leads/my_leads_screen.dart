import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class MyLeadsScreen extends StatefulWidget {
  const MyLeadsScreen({super.key});

  @override
  State<MyLeadsScreen> createState() => _MyLeadsScreenState();
}

class _MyLeadsScreenState extends State<MyLeadsScreen> with RouteAware {
  List<Map<String, dynamic>> _leads = [];
  bool _isLoading = true;
  String? _error;
  RealtimeChannel? _realtimeChannel;

  static final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _fetchMyLeads().then((_) => _subscribeToRealtime());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      _routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _fetchMyLeads();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToRealtime() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _realtimeChannel = Supabase.instance.client
        .channel('my_leads_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'requests',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'assigned_master_id',
            value: userId,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchMyLeads();
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchMyLeads() async {
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
            'id, category_name, service_name, vehicle_info, description, '
            'address_full, preferred_date, status, created_at, '
            'assigned_master_id, client_id',
          )
          .eq('assigned_master_id', userId)
          .inFilter('status', ['assigned', 'scheduled'])
          .order('created_at', ascending: false);

      final leads = List<Map<String, dynamic>>.from(response);

      // Fetch client names
      final clientIds = leads
          .where((r) => r['client_id'] != null)
          .map((r) => r['client_id'] as String)
          .toSet()
          .toList();

      Map<String, String> clientNames = {};
      if (clientIds.isNotEmpty) {
        try {
          final clientsResponse = await Supabase.instance.client
              .from('users')
              .select('id, name')
              .inFilter('id', clientIds);
          for (final c in clientsResponse) {
            final id = c['id'] as String?;
            final name = c['name'] as String?;
            if (id != null && name != null) {
              clientNames[id] = name;
            }
          }
        } catch (_) {}
      }

      // Attach client name to each lead
      final enriched = leads.map((r) {
        final cid = r['client_id'] as String?;
        return {...r, 'client_name': cid != null ? clientNames[cid] : null};
      }).toList();

      if (mounted) {
        setState(() {
          _leads = enriched;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load leads. Pull to refresh.';
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
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
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

  Color _statusColor(String status) {
    switch (status) {
      case 'searching':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'in_progress':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Leads'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pushReplacementNamed(context, '/master-dashboard'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              SizedBox(height: 2.h),
              Expanded(child: _buildBody(theme)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your accepted leads',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'My Leads',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          child: CustomIconWidget(
            iconName: 'bookmark',
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildSkeleton(theme);
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: theme.colorScheme.error,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _fetchMyLeads,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'bookmark_border',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text('No leads yet', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Text(
              'Accepted requests will appear here.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _fetchMyLeads,
      color: theme.colorScheme.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _leads.length,
        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
        itemBuilder: (context, index) {
          final lead = _leads[index];
          return _MyLeadCard(
            lead: lead,
            formatDate: _formatDate,
            formatServiceTime: _formatServiceTime,
          );
        },
      ),
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        return Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
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
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 22,
                    width: 70,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
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
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(height: 0.5.h),
              Container(
                height: 12,
                width: 140,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.04),
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

class _MyLeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final String Function(String?) formatDate;
  final String Function(String?, String?) formatServiceTime;

  const _MyLeadCard({
    required this.lead,
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

  void _openChat(BuildContext context) {
    final requestId = lead['id'] as String?;
    final categoryName = lead['category_name'] as String? ?? 'Service Request';
    final clientId = lead['client_id'] as String?;

    Navigator.of(context, rootNavigator: true).pushNamed(
      '/real-time-messaging',
      arguments: {
        'request_id': requestId,
        'service_title': categoryName,
        'other_user_id': clientId,
      },
    );
  }

  void _openDetails(BuildContext context) {
    final requestId = lead['id'] as String?;
    if (requestId == null) return;
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed('/lead-details', arguments: {'request_id': requestId});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final categoryName = (lead['category_name'] as String?)?.isNotEmpty == true
        ? lead['category_name'] as String
        : 'General';
    final serviceName = lead['service_name'] as String?;
    final vehicleInfo = lead['vehicle_info'] as String?;
    final description = lead['description'] as String? ?? '';
    final addressFull = lead['address_full'] as String?;
    final preferredDate = lead['preferred_date'] as String?;
    final status = lead['status'] as String? ?? '';
    final createdAt = lead['created_at'] as String?;
    final clientName = lead['client_name'] as String?;

    final badgeColor = _statusColor(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isDark ? AppTheme.dividerDark : AppTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? AppTheme.shadowDark : AppTheme.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Category + status badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: 'build',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  categoryName,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
            ],
          ),

          // Service name as main title
          if (serviceName != null && serviceName.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                serviceName,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Text(
                categoryName,
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111111),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          // Vehicle info
          if (vehicleInfo != null && vehicleInfo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'directions_car',
                  color: Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Vehicle: $vehicleInfo',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Description
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Address
          if (addressFull != null && addressFull.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'location_on',
                  color: Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    addressFull,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Preferred date
          if (preferredDate != null && preferredDate.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'calendar_today',
                  color: Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  preferredDate,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // Client name
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CustomIconWidget(
                    iconName: 'person',
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                clientName != null ? 'Client: $clientName' : 'Client: —',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),

          // Divider
          const SizedBox(height: 10),
          Divider(
            height: 1,
            thickness: 1,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
          ),

          // Request date
          if (createdAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const CustomIconWidget(
                  iconName: 'schedule',
                  color: Color(0xFF9E9E9E),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  formatDate(createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],

          // Actions row
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openChat(context),
                  icon: const CustomIconWidget(
                    iconName: 'chat_bubble_outline',
                    color: Colors.white,
                    size: 14,
                  ),
                  label: Text(
                    'Open Chat',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
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
                  onPressed: () => _openDetails(context),
                  icon: CustomIconWidget(
                    iconName: 'info_outline',
                    color: theme.colorScheme.primary,
                    size: 14,
                  ),
                  label: Text(
                    'Details',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: theme.colorScheme.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
