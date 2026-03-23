import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';

class MasterDashboardInitialPage extends StatefulWidget {
  const MasterDashboardInitialPage({super.key});

  @override
  State<MasterDashboardInitialPage> createState() =>
      _MasterDashboardInitialPageState();
}

class _MasterDashboardInitialPageState
    extends State<MasterDashboardInitialPage> {
  bool _isLoading = true;
  bool _hasError = false;
  int _activeLeads = 0;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final response = await Supabase.instance.client
          .from('requests')
          .select('id')
          .eq('assigned_master_id', userId)
          .eq('status', 'assigned');
      if (mounted) {
        setState(() {
          _activeLeads = (response as List).length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  void _navigate(String route) {
    if (!kIsWeb) HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStats,
        color: theme.colorScheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overview',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.5.h),
              _isLoading
                  ? _buildSkeletonStats(theme)
                  : _hasError
                  ? _buildErrorState(theme)
                  : _buildStatsGrid(theme),
              SizedBox(height: 3.h),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.5.h),
              _buildActionButton(
                theme: theme,
                icon: 'search',
                label: 'View Available Leads',
                subtitle: 'Browse new service requests',
                color: AppTheme.primaryLight,
                onTap: () => _navigate(AppRoutes.availableLeads),
              ),
              SizedBox(height: 1.5.h),
              _buildActionButton(
                theme: theme,
                icon: 'assignment',
                label: 'View My Leads',
                subtitle: 'Manage your active assignments',
                color: AppTheme.successLight,
                onTap: () => _navigate(AppRoutes.myLeads),
              ),
              SizedBox(height: 1.5.h),
              _buildActionButton(
                theme: theme,
                icon: 'chat_bubble_outline',
                label: 'Messages',
                subtitle: 'Chat with your clients',
                color: AppTheme.accentColor,
                onTap: () => _navigate(AppRoutes.realTimeMessaging),
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final stats = [
      {
        'label': 'Active Leads',
        'value': '$_activeLeads',
        'icon': 'trending_up',
        'color': AppTheme.primaryLight,
      },
      {
        'label': 'Completion Rate',
        'value': '—',
        'icon': 'check_circle_outline',
        'color': AppTheme.successLight,
      },
      {
        'label': 'Earnings',
        'value': '\$0',
        'icon': 'account_balance_wallet',
        'color': AppTheme.accentColor,
      },
    ];
    return Row(
      children: stats.map((stat) {
        final idx = stats.indexOf(stat);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < stats.length - 1 ? 2.w : 0),
            child: _StatCard(stat: stat),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSkeletonStats(ThemeData theme) {
    return Row(
      children: List.generate(3, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 2 ? 2.w : 0),
            child: Container(
              height: 10.h,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.errorLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorLight.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: AppTheme.errorLight,
            size: 20,
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'Failed to load stats.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.errorLight,
              ),
            ),
          ),
          TextButton(onPressed: _fetchStats, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required String icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: CustomIconWidget(iconName: icon, color: color, size: 22),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              CustomIconWidget(
                iconName: 'chevron_right',
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = stat['color'] as Color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomIconWidget(
            iconName: stat['icon'] as String,
            color: color,
            size: 20,
          ),
          SizedBox(height: 0.8.h),
          Text(
            stat['value'] as String,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            stat['label'] as String,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
