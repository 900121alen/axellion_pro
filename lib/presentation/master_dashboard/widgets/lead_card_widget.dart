import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class LeadCardWidget extends StatelessWidget {
  final Map<String, dynamic> lead;
  final VoidCallback onViewDetails;
  final VoidCallback onBuyLead;
  final Function(String) onSwipeAction;
  final VoidCallback onLongPress;

  const LeadCardWidget({
    super.key,
    required this.lead,
    required this.onViewDetails,
    required this.onBuyLead,
    required this.onSwipeAction,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPurchased = lead['isPurchased'] as bool;
    final isSaved = lead['isSaved'] as bool;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Slidable(
        key: ValueKey(lead['id']),
        startActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.6,
          children: [
            SlidableAction(
              onPressed: (_) => onSwipeAction('save'),
              backgroundColor: AppTheme.secondaryLight,
              foregroundColor: Colors.white,
              icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
              label: isSaved ? 'Unsave' : 'Save',
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
            ),
            SlidableAction(
              onPressed: (_) => onSwipeAction('share'),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Share',
            ),
            SlidableAction(
              onPressed: (_) => onSwipeAction('report'),
              backgroundColor: AppTheme.errorLight,
              foregroundColor: Colors.white,
              icon: Icons.flag,
              label: 'Report',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPurchased
                  ? AppTheme.successLight.withValues(alpha: 0.4)
                  : theme.colorScheme.outline,
            ),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(theme, isPurchased, isSaved),
              Padding(
                padding: EdgeInsets.fromLTRB(3.w, 0, 3.w, 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead['description'] as String,
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 1.5.h),
                    _buildMetaRow(theme),
                    SizedBox(height: 1.5.h),
                    _buildActionRow(theme, isPurchased),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(ThemeData theme, bool isPurchased, bool isSaved) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: 14.h,
            child: CustomImageWidget(
              imageUrl: lead['image'] as String,
              width: double.infinity,
              height: 14.h,
              fit: BoxFit.cover,
              semanticLabel: lead['semanticLabel'] as String,
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lead['category'] as String,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (isPurchased)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Purchased',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          if (isSaved && !isPurchased)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                child: CustomIconWidget(
                  iconName: 'bookmark',
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Text(
                lead['title'] as String,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(ThemeData theme) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: 'location_on',
          color: theme.colorScheme.onSurfaceVariant,
          size: 14,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${lead['location']} • ${lead['distance']}',
            style: theme.textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        CustomIconWidget(
          iconName: 'star',
          color: AppTheme.accentColor,
          size: 14,
        ),
        const SizedBox(width: 2),
        Text(
          '${lead['clientRating']} (${lead['clientReviews']})',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildActionRow(ThemeData theme, bool isPurchased) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '\$${lead['budgetMin']} - \$${lead['budgetMax']}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppTheme.successLight,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                lead['postedTime'] as String,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
        SizedBox(width: 2.w),
        OutlinedButton(
          onPressed: onViewDetails,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text('Details'),
        ),
        SizedBox(width: 2.w),
        isPurchased
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
                decoration: BoxDecoration(
                  color: AppTheme.successLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppTheme.successLight.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'Owned',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.successLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: onBuyLead,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Buy Lead'),
              ),
      ],
    );
  }
}
