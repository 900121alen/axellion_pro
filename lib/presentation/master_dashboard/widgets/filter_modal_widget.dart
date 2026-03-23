import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FilterModalWidget extends StatefulWidget {
  final Map<String, dynamic> activeFilters;
  final Function(Map<String, dynamic>) onApply;
  final VoidCallback onClear;

  const FilterModalWidget({
    super.key,
    required this.activeFilters,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterModalWidget> createState() => _FilterModalWidgetState();
}

class _FilterModalWidgetState extends State<FilterModalWidget> {
  String _selectedCategory = 'All';
  double _maxBudget = 1000;
  double _locationRadius = 10;

  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'HVAC',
    'Carpentry',
    'Painting',
    'Landscaping',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.activeFilters['category'] as String? ?? 'All';
    _maxBudget =
        (widget.activeFilters['maxBudget'] as num?)?.toDouble() ?? 1000;
    _locationRadius =
        (widget.activeFilters['locationRadius'] as num?)?.toDouble() ?? 10;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(4.w, 2.h, 4.w, 4.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter Leads', style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: widget.onClear,
                child: const Text('Clear All'),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Text('Category', style: theme.textTheme.titleSmall),
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                  child: Text(
                    cat,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : theme.colorScheme.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Budget', style: theme.textTheme.titleSmall),
              Text(
                '\$${_maxBudget.toInt()}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxBudget,
            min: 50,
            max: 2000,
            divisions: 39,
            onChanged: (v) => setState(() => _maxBudget = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Location Radius', style: theme.textTheme.titleSmall),
              Text(
                '${_locationRadius.toInt()} mi',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: _locationRadius,
            min: 1,
            max: 50,
            divisions: 49,
            onChanged: (v) => setState(() => _locationRadius = v),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onApply({
                'category': _selectedCategory,
                'maxBudget': _maxBudget.toInt(),
                'locationRadius': _locationRadius.toInt(),
              }),
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
