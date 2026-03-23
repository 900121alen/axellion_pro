import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LeadStatusBadgeWidget extends StatelessWidget {
  final String status;

  const LeadStatusBadgeWidget({super.key, required this.status});

  Color _statusColor(BuildContext context) {
    switch (status.toLowerCase()) {
      case 'searching':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'answered':
        return Colors.green;
      case 'relisted':
        return Colors.yellow.shade700;
      case 'archived':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 2.w),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
