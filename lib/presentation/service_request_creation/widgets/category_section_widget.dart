import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _fieldBg = Color(0xFF1C1C2E);

class CategorySectionWidget extends StatelessWidget {
  final String? selectedCategory;
  final String? selectedSubCategory;
  final String? error;
  final void Function(String category, String? subCategory) onCategorySelected;

  const CategorySectionWidget({
    super.key,
    required this.selectedCategory,
    required this.selectedSubCategory,
    required this.error,
    required this.onCategorySelected,
  });

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Home Repair',
      'icon': 'home_repair_service',
      'subcategories': [
        'Plumbing',
        'Electrical',
        'Carpentry',
        'Painting',
        'Roofing',
      ],
    },
    {
      'name': 'Cleaning',
      'icon': 'cleaning_services',
      'subcategories': [
        'Deep Cleaning',
        'Regular Cleaning',
        'Move-in/out',
        'Office Cleaning',
      ],
    },
    {
      'name': 'Moving',
      'icon': 'local_shipping',
      'subcategories': ['Local Move', 'Long Distance', 'Packing', 'Storage'],
    },
    {
      'name': 'Landscaping',
      'icon': 'yard',
      'subcategories': [
        'Lawn Mowing',
        'Tree Trimming',
        'Garden Design',
        'Snow Removal',
      ],
    },
    {
      'name': 'Tech Support',
      'icon': 'computer',
      'subcategories': [
        'Computer Repair',
        'Network Setup',
        'Smart Home',
        'Data Recovery',
      ],
    },
    {
      'name': 'Tutoring',
      'icon': 'school',
      'subcategories': ['Math', 'Science', 'Languages', 'Music', 'Arts'],
    },
  ];

  void _showCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161625),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollCtrl) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              child: const Text(
                'Select Category',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Divider(color: Colors.white.withValues(alpha: 0.08)),
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final isSelected = selectedCategory == cat['name'] as String;
                  return Theme(
                    data: Theme.of(
                      ctx,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _neonBlue.withValues(alpha: 0.2)
                              : Colors.white.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: CustomIconWidget(
                          iconName: cat['icon'] as String,
                          color: isSelected
                              ? _neonBlue
                              : Colors.white.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        cat['name'] as String,
                        style: TextStyle(
                          color: isSelected ? _neonBlue : Colors.white,
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      iconColor: Colors.white.withValues(alpha: 0.4),
                      collapsedIconColor: Colors.white.withValues(alpha: 0.4),
                      children: (cat['subcategories'] as List<String>).map((
                        sub,
                      ) {
                        final isSubSelected =
                            selectedCategory == cat['name'] &&
                            selectedSubCategory == sub;
                        return ListTile(
                          contentPadding: EdgeInsets.only(
                            left: 8.w,
                            right: 4.w,
                          ),
                          title: Text(
                            sub,
                            style: TextStyle(
                              color: isSubSelected
                                  ? _neonBlue
                                  : Colors.white.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                          trailing: isSubSelected
                              ? const Icon(
                                  Icons.check_circle,
                                  color: _neonBlue,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            onCategorySelected(cat['name'] as String, sub);
                            Navigator.pop(ctx);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              'Category',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        selectedCategory != null && selectedCategory!.isNotEmpty
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 0.7.h,
                    ),
                    decoration: BoxDecoration(
                      color: _neonBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                        color: _neonBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selectedSubCategory != null
                              ? '$selectedCategory › $selectedSubCategory'
                              : selectedCategory!,
                          style: const TextStyle(
                            color: _neonBlue,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        GestureDetector(
                          onTap: () => onCategorySelected('', null),
                          child: const Icon(
                            Icons.close,
                            color: _neonBlue,
                            size: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showCategorySheet(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.7.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : InkWell(
                onTap: () => _showCategorySheet(context),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _fieldBg,
                    border: Border.all(
                      color: error != null
                          ? const Color(0xFFEF4444)
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'category',
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 20,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Select a service category',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.35),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      CustomIconWidget(
                        iconName: 'keyboard_arrow_down',
                        color: Colors.white.withValues(alpha: 0.35),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 12),
            child: Text(
              error!,
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12),
            ),
          ),
      ],
    );
  }
}
