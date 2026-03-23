import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/lead_details_skeleton_widget.dart';

class LeadDetailsScreen extends StatefulWidget {
  const LeadDetailsScreen({super.key});

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  bool _isLoading = true;
  bool _isBuying = false;
  String? _error;
  Map<String, dynamic>? _requestData;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading && _requestData == null && _error == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      String? requestId;
      if (args is Map) {
        requestId = args['request_id'] as String?;
      } else if (args is String) {
        requestId = args;
      }
      if (requestId != null && requestId.isNotEmpty) {
        _fetchRequest(requestId);
      } else {
        setState(() {
          _error = 'Invalid request ID.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchRequest(String requestId) async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final response = await Supabase.instance.client
          .from('requests')
          .select(
            'id, category_name, service_name, status, vehicle_info, description, address_full, preferred_date, preferred_time, media_url, assigned_master_id, created_at',
          )
          .eq('id', requestId)
          .single();

      if (mounted) {
        setState(() {
          _requestData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load lead details. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onBuyLead() async {
    final data = _requestData;
    if (data == null) return;
    final requestId = data['id'] as String?;
    if (requestId == null) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Not authenticated. Please log in again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    // Confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'shopping_cart',
                  color: theme.colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Confirm Purchase'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Purchase this lead for \$25?',
                style: theme.textTheme.bodyMedium,
              ),
              SizedBox(height: 1.5.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'info_outline',
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment is simulated. No real charge will occur.',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Buy for \$25'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isBuying = true);

    try {
      final updateResponse = await Supabase.instance.client
          .from('requests')
          .update({'status': 'assigned', 'assigned_master_id': currentUser.id})
          .eq('id', requestId)
          .eq('status', 'searching')
          .select();

      if (!mounted) return;

      if ((updateResponse as List).isEmpty) {
        setState(() => _isBuying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lead already taken by another technician.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }

      if (!kIsWeb) HapticFeedback.mediumImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Lead purchased! Client contact is now unlocked.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/my-leads',
        (route) => route.settings.name == '/master-dashboard' || route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBuying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Lead Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: _buildBody(theme),
      bottomNavigationBar: _buildBottomBar(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) return const LeadDetailsSkeletonWidget();
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomIconWidget(
                iconName: 'wifi_off',
                color: theme.colorScheme.error,
                size: 56,
              ),
              SizedBox(height: 2.h),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton.icon(
                onPressed: () {
                  final args = ModalRoute.of(context)?.settings.arguments;
                  String? requestId;
                  if (args is Map) requestId = args['request_id'] as String?;
                  if (args is String) requestId = args;
                  if (requestId != null) _fetchRequest(requestId);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_requestData == null) return const SizedBox.shrink();
    return _buildContent(theme);
  }

  Widget _buildContent(ThemeData theme) {
    final data = _requestData!;
    final isDark = theme.brightness == Brightness.dark;

    final categoryName = (data['category_name'] as String?)?.isNotEmpty == true
        ? data['category_name'] as String
        : 'General';
    final serviceName = data['service_name'] as String?;
    final vehicleInfo = data['vehicle_info'] as String?;
    final description = data['description'] as String? ?? '';
    final addressFull = data['address_full'] as String?;
    final preferredDate = data['preferred_date'] as String?;
    final preferredTime = data['preferred_time'] as String?;
    final mediaUrl = data['media_url'];
    final assignedMasterId = data['assigned_master_id'] as String?;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isAlreadyMine =
        assignedMasterId != null && assignedMasterId == currentUserId;

    // Parse photo URLs
    List<String> photoUrls = [];
    if (mediaUrl != null) {
      if (mediaUrl is List) {
        photoUrls = mediaUrl.map((e) => e.toString()).toList();
      } else if (mediaUrl is String && mediaUrl.isNotEmpty) {
        photoUrls = [mediaUrl];
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pre-purchase notice banner — only shown when NOT yet purchased
          if (!isAlreadyMine) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'lock_outline',
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Buy this lead to unlock client contact & chat.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.5.h),
          ],

          // Category
          _InfoCard(
            isDark: isDark,
            theme: theme,
            iconName: 'category',
            label: 'Category',
            value: categoryName,
          ),
          SizedBox(height: 1.5.h),

          // Service
          if (serviceName != null && serviceName.isNotEmpty) ...[
            _InfoCard(
              isDark: isDark,
              theme: theme,
              iconName: 'build',
              label: 'Service',
              value: serviceName,
            ),
            SizedBox(height: 1.5.h),
          ],

          // Vehicle
          if (vehicleInfo != null && vehicleInfo.isNotEmpty) ...[
            _InfoCard(
              isDark: isDark,
              theme: theme,
              iconName: 'directions_car',
              label: 'Vehicle',
              value: vehicleInfo,
            ),
            SizedBox(height: 1.5.h),
          ],

          // Description
          _InfoCard(
            isDark: isDark,
            theme: theme,
            iconName: 'description',
            label: 'Description',
            value: description.isNotEmpty
                ? description
                : 'No description provided.',
            multiLine: true,
          ),
          SizedBox(height: 1.5.h),

          // Location
          if (addressFull != null && addressFull.isNotEmpty) ...[
            _InfoCard(
              isDark: isDark,
              theme: theme,
              iconName: 'location_on',
              label: 'Location',
              value: addressFull,
            ),
            SizedBox(height: 1.5.h),
          ],

          // Service Date
          if (preferredDate != null && preferredDate.isNotEmpty) ...[
            _InfoCard(
              isDark: isDark,
              theme: theme,
              iconName: 'calendar_today',
              label: 'Service Date',
              value: preferredDate,
            ),
            SizedBox(height: 1.5.h),
          ],

          // Preferred Time
          if (preferredTime != null && preferredTime.isNotEmpty) ...[
            _InfoCard(
              isDark: isDark,
              theme: theme,
              iconName: 'access_time',
              label: 'Preferred Time',
              value: preferredTime,
            ),
            SizedBox(height: 1.5.h),
          ],

          // Photos
          if (photoUrls.isNotEmpty) ...[
            _PhotosSection(isDark: isDark, theme: theme, photoUrls: photoUrls),
            SizedBox(height: 1.5.h),
          ],

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildBottomBar(ThemeData theme) {
    final status = _requestData?['status'] as String? ?? 'searching';
    final assignedMasterId = _requestData?['assigned_master_id'] as String?;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    // If this lead is already purchased by the current technician, hide the button entirely
    final isAlreadyMine =
        assignedMasterId != null && assignedMasterId == currentUserId;
    if (isAlreadyMine) return const SizedBox.shrink();

    final isSearching = status == 'searching';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(4.w, 1.h, 4.w, 2.h),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (!_isLoading && isSearching && !_isBuying)
                ? _onBuyLead
                : null,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 1.8.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isBuying
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: isSearching ? 'shopping_cart' : 'lock',
                        color: theme.colorScheme.onPrimary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSearching ? 'Buy Lead (\$25)' : 'Already Assigned',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Info Card ───────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final String iconName;
  final String label;
  final String value;
  final bool multiLine;

  const _InfoCard({
    required this.isDark,
    required this.theme,
    required this.iconName,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: multiLine
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: iconName,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: multiLine ? 1.5 : null,
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

// ─── Photos Section ──────────────────────────────────────────────────────────

class _PhotosSection extends StatelessWidget {
  final bool isDark;
  final ThemeData theme;
  final List<String> photoUrls;

  const _PhotosSection({
    required this.isDark,
    required this.theme,
    required this.photoUrls,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.8.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomIconWidget(
                  iconName: 'photo_library',
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Photos',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            height: 12.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullScreen(context, photoUrls[index]),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photoUrls[index],
                      width: 12.h,
                      height: 12.h,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 12.h,
                        height: 12.h,
                        color: theme.colorScheme.outline.withValues(alpha: 0.1),
                        child: CustomIconWidget(
                          iconName: 'broken_image',
                          color: theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  void _showFullScreen(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
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
}
