import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/available_lead_card_widget.dart';

class AvailableLeadsScreen extends StatefulWidget {
  const AvailableLeadsScreen({super.key});

  @override
  State<AvailableLeadsScreen> createState() => _AvailableLeadsScreenState();
}

class _AvailableLeadsScreenState extends State<AvailableLeadsScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  List<Map<String, dynamic>> _leads = [];

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await Supabase.instance.client
          .from('requests')
          .select('*, category_name, service_name, categories(name)')
          .eq('status', 'searching')
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _leads = List<Map<String, dynamic>>.from(response as List);
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

  Future<void> _buyLead(Map<String, dynamic> lead) async {
    final requestId = lead['id'] as String;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final confirmed = await _showPurchaseConfirmation();
    if (!confirmed) return;

    try {
      final updateResponse = await Supabase.instance.client
          .from('requests')
          .update({
            'status': 'assigned',
            'assigned_master_id': userId,
            'assigned_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId)
          .eq('status', 'searching')
          .select();

      if (!mounted) return;

      if ((updateResponse as List).isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('DB Error: Lead no longer available'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        if (!kIsWeb) HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead purchased successfully!'),
            backgroundColor: AppTheme.successLight,
          ),
        );
        _fetchLeads();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DB Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<bool> _showPurchaseConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: const Text('Purchase this lead for \$25?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Available Leads'),
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
      body: RefreshIndicator(
        onRefresh: _fetchLeads,
        color: theme.colorScheme.primary,
        child: _buildBody(theme),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return _buildSkeleton(theme);
    if (_hasError) return _buildErrorState(theme);
    if (_leads.isEmpty) return _buildEmptyState(theme);
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: _leads.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        final lead = _leads[index];
        return AvailableLeadCardWidget(
          lead: lead,
          onDetails: () {
            Navigator.pushNamed(
              context,
              '/lead-details',
              arguments: {'request_id': lead['id'] as String},
            );
          },
          onBuyLead: () => _buyLead(lead),
        );
      },
    );
  }

  Widget _buildSkeleton(ThemeData theme) {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: 1.5.h),
      itemBuilder: (_, __) => Container(
        height: 18.h,
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'search_off',
                color: theme.colorScheme.onSurfaceVariant,
                size: 64,
              ),
              SizedBox(height: 2.h),
              Text(
                'No available leads right now',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.h),
              Text(
                'Check back later for new service requests.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'error_outline',
              color: AppTheme.errorLight,
              size: 48,
            ),
            SizedBox(height: 2.h),
            Text('Failed to load leads', style: theme.textTheme.titleMedium),
            SizedBox(height: 1.h),
            ElevatedButton(onPressed: _fetchLeads, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}