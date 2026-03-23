import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class LeadsFeedInitialPage extends StatefulWidget {
  const LeadsFeedInitialPage({super.key});

  @override
  State<LeadsFeedInitialPage> createState() => _LeadsFeedInitialPageState();
}

class _LeadsFeedInitialPageState extends State<LeadsFeedInitialPage>
    with RouteAware {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _leads = [];
  bool _hasFetchedOnce = false;

  static final RouteObserver<ModalRoute<void>> _routeObserver =
      RouteObserver<ModalRoute<void>>();

  @override
  void initState() {
    super.initState();
    _fetchLeads();
    _hasFetchedOnce = true;
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
    // Called when user navigates back to this screen
    _fetchLeads();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('requests')
          .select(
            'id, description, area_name, budget_option, created_at, categories(name)',
          )
          .eq('status', 'searching')
          .order('created_at', ascending: false)
          .limit(50);

      if (mounted) {
        setState(() {
          _leads = List<Map<String, dynamic>>.from(response);
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

  String _formatTime(String? isoString) {
    if (isoString == null) return 'Recently';
    try {
      final dt = DateTime.parse(isoString);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    } catch (_) {
      return 'Recently';
    }
  }

  Future<void> _handleRefresh() async {
    if (!kIsWeb) HapticFeedback.mediumImpact();
    await _fetchLeads();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              SizedBox(height: 2.h),
              _buildSectionTitle(theme),
              SizedBox(height: 1.h),
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
                'Available Work',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Leads Feed',
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
            iconName: 'person',
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Open Requests',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!_isLoading && _leads.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_leads.length} leads',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return _buildSkeleton(theme);
    }
    if (_error != null && _leads.isEmpty) {
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
            ElevatedButton(onPressed: _fetchLeads, child: const Text('Retry')),
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
              iconName: 'search_off',
              color: theme.colorScheme.onSurfaceVariant,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text('No open requests', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            Text(
              'Check back later for new service requests.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: theme.colorScheme.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _leads.length,
        separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
        itemBuilder: (context, index) {
          final lead = _leads[index];
          return _LeadCard(lead: lead, formatTime: _formatTime);
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
                    height: 20,
                    width: 80,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.08,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    height: 14,
                    width: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.05,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              SizedBox(height: 0.5.h),
              Container(
                height: 12,
                width: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
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

class _LeadCard extends StatelessWidget {
  final Map<String, dynamic> lead;
  final String Function(String?) formatTime;

  const _LeadCard({required this.lead, required this.formatTime});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = lead['categories'] as Map<String, dynamic>?;
    final categoryName = category?['name'] as String? ?? 'General';
    final description = lead['description'] as String? ?? '';
    final areaName = lead['area_name'] as String? ?? '';
    final budgetOption = lead['budget_option'] as String? ?? '';
    final createdAt = lead['created_at'] as String?;

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/lead-details',
          arguments: {'request_id': lead['id']},
        );
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: EdgeInsets.all(4.w),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    categoryName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formatTime(createdAt),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            if (description.isNotEmpty)
              Text(
                description,
                style: theme.textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            SizedBox(height: 1.h),
            Row(
              children: [
                if (areaName.isNotEmpty) ...[
                  CustomIconWidget(
                    iconName: 'location_on',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    areaName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (budgetOption.isNotEmpty) ...[
                  CustomIconWidget(
                    iconName: 'attach_money',
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    budgetOption,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
