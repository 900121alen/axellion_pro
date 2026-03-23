import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

const Color _neonBlue = Color(0xFF3A8BFF);

class BudgetSectionWidget extends StatelessWidget {
  final double budgetMin;
  final double budgetMax;
  final bool isHourlyRate;
  final void Function(double min, double max, bool isHourly) onBudgetChanged;

  const BudgetSectionWidget({
    super.key,
    required this.budgetMin,
    required this.budgetMax,
    required this.isHourlyRate,
    required this.onBudgetChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: _neonBlue,
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            SizedBox(width: 2.w),
            const Text(
              'Budget',
              style: TextStyle(
                color: Color(0xFF1A1A2A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.4.h),
              decoration: BoxDecoration(
                color: const Color(0xFFD0D3DC),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: const Color(0xFFB0B3BC)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Fixed',
                    style: TextStyle(
                      color: !isHourlyRate
                          ? const Color(0xFF1A1A2A)
                          : const Color(0xFF8888AA),
                      fontSize: 11,
                      fontWeight: !isHourlyRate
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: isHourlyRate,
                      onChanged: (v) =>
                          onBudgetChanged(budgetMin, budgetMax, v),
                      activeThumbColor: _neonBlue,
                      inactiveThumbColor: const Color(0xFF5A5A7A),
                      inactiveTrackColor: const Color(0xFFB0B3BC),
                    ),
                  ),
                  Text(
                    'Hourly',
                    style: TextStyle(
                      color: isHourlyRate ? _neonBlue : const Color(0xFF8888AA),
                      fontSize: 11,
                      fontWeight: isHourlyRate
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _neonBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                '\$${budgetMin.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: _neonBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              'to',
              style: TextStyle(color: const Color(0xFF5A5A7A), fontSize: 12),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
              decoration: BoxDecoration(
                color: _neonBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
              ),
              child: Text(
                '\$${budgetMax.toStringAsFixed(0)}${isHourlyRate ? '/hr' : ''}',
                style: const TextStyle(
                  color: _neonBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _neonBlue,
            inactiveTrackColor: const Color(0xFFD0D3DC),
            thumbColor: _neonBlue,
            overlayColor: _neonBlue.withValues(alpha: 0.2),
            valueIndicatorColor: _neonBlue,
            valueIndicatorTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
            trackHeight: 3,
          ),
          child: RangeSlider(
            values: RangeValues(budgetMin, budgetMax),
            min: 0,
            max: 5000,
            divisions: 100,
            labels: RangeLabels(
              '\$${budgetMin.toStringAsFixed(0)}',
              '\$${budgetMax.toStringAsFixed(0)}',
            ),
            onChanged: (values) =>
                onBudgetChanged(values.start, values.end, isHourlyRate),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$0',
              style: TextStyle(color: const Color(0xFF8888AA), fontSize: 11),
            ),
            Text(
              '\$5,000',
              style: TextStyle(color: const Color(0xFF8888AA), fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}
