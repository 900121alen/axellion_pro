import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _darkBg = Color(0xFFEEEFF4);
const Color _cardBg = Color(0xFFFFFFFF);
const Color _searchBg = Color(0xFFDDE0E8);

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  bool _searchFocused = false;

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Detailing & Car Wash',
      'icon': 'local_car_wash',
      'color': Color(0xFF3A8BFF),
    },
    {'name': 'Wheel & Tire', 'icon': 'tire_repair', 'color': Color(0xFF9B59B6)},
    {'name': 'Maintenance', 'icon': 'build', 'color': Color(0xFFF39C12)},
    {
      'name': 'Mechanical Issues',
      'icon': 'engineering',
      'color': Color(0xFF27AE60),
    },
    {'name': 'Electrical', 'icon': 'bolt', 'color': Color(0xFFE74C3C)},
    {
      'name': 'Exterior & Body',
      'icon': 'directions_car',
      'color': Color(0xFF00BCD4),
    },
    {
      'name': 'Interior',
      'icon': 'airline_seat_recline_normal',
      'color': Color(0xFFE91E8C),
    },
    {'name': 'Diagnostics', 'icon': 'search', 'color': Color(0xFFFF9800)},
  ];

  static const Map<String, List<String>> _categoryServices = {
    'Detailing & Car Wash': [
      'Full Detail',
      'Exterior Wash',
      'Interior Cleaning',
      'Paint Protection',
      'Ceramic Coating',
      'Steam Cleaning',
    ],
    'Wheel & Tire': [
      'Wheel Repair',
      'Wheel Painting',
      'Curb Rash Repair',
      'Flat Tire Repair',
      'Tire Replacement',
      'Tire Rotation',
    ],
    'Maintenance': [
      'Oil Change',
      'Filter Replacement',
      'Fluid Top-Up',
      'Spark Plug Replacement',
      'Belt Inspection',
      'Battery Check',
    ],
    'Mechanical Issues': [
      'Brake Repair',
      'Suspension Repair',
      'Transmission Service',
      'Engine Repair',
      'Exhaust Repair',
      'Steering Repair',
    ],
    'Electrical': [
      'Battery Replacement',
      'Alternator Repair',
      'Starter Motor',
      'Wiring Repair',
      'Lighting Repair',
      'Fuse Replacement',
    ],
    'Exterior & Body': [
      'Dent Removal',
      'Paint Touch-Up',
      'Scratch Repair',
      'Bumper Repair',
      'Window Tinting',
      'Windshield Repair',
    ],
    'Interior': [
      'Seat Repair',
      'Dashboard Repair',
      'Carpet Cleaning',
      'Headliner Repair',
      'Door Panel Repair',
      'AC Repair',
    ],
    'Diagnostics': [
      'Engine Diagnostics',
      'OBD Scan',
      'Electrical Diagnostics',
      'Pre-Purchase Inspection',
      'Emissions Test',
      'Full Vehicle Inspection',
    ],
  };

  List<Map<String, String>> get _searchResults {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    final results = <Map<String, String>>[];
    for (final category in _categories) {
      final catName = category['name'] as String;
      final services = _categoryServices[catName] ?? [];
      for (final service in services) {
        if (service.toLowerCase().contains(query) ||
            catName.toLowerCase().contains(query)) {
          results.add({'service': service, 'category': catName});
        }
      }
    }
    return results;
  }

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onCategoryTap(String categoryName) {
    Navigator.of(
      context,
    ).pushNamed(AppRoutes.serviceCategories, arguments: categoryName);
  }

  void _onSearchResultTap(String serviceName, String categoryName) {
    _searchController.clear();
    setState(() => _searchQuery = '');
    Navigator.of(context).pushNamed(
      AppRoutes.serviceRequestCreation,
      arguments: {
        'name': serviceName,
        'id': null,
        'price_range_text': categoryName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimal logo placeholder header
            _buildMinimalHeader(),
            // Search bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: _buildSearchBar(),
            ),
            if (_searchQuery.isNotEmpty)
              Expanded(child: _buildSearchResults())
            else ...[
              Padding(
                padding: EdgeInsets.fromLTRB(4.w, 1.5.h, 4.w, 2.h),
                child: Text(
                  'Service Categories',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A2A),
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: GridView.builder(
                    physics: const BouncingScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      return _CategoryCard(
                        name: cat['name'] as String,
                        iconName: cat['icon'] as String,
                        accentColor: cat['color'] as Color,
                        onTap: () => _onCategoryTap(cat['name'] as String),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 2.h, bottom: 0.5.h, left: 4.w, right: 4.w),
      child: SizedBox(
        height: 36,
        // Minimal placeholder — a small logo can be placed here later
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _neonBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                color: _neonBlue.withValues(alpha: 0.25),
                width: 1.0,
              ),
            ),
            child: Center(
              child: CustomIconWidget(
                iconName: 'auto_awesome',
                color: _neonBlue.withValues(alpha: 0.8),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _searchBg,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: _searchFocused
              ? _neonBlue.withValues(alpha: 0.6)
              : Colors.transparent,
          width: 1.0,
        ),
        boxShadow: _searchFocused
            ? [
                BoxShadow(
                  color: _neonBlue.withValues(alpha: 0.12),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocus,
        onChanged: (val) => setState(() => _searchQuery = val),
        style: GoogleFonts.inter(color: const Color(0xFF1A1A2A), fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search services...',
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 14,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: CustomIconWidget(
              iconName: 'search',
              color: const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 50,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _searchResults;
    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search_off',
              color: const Color(0xFF6B7280),
              size: 48,
            ),
            SizedBox(height: 1.5.h),
            Text(
              'No services found for "$_searchQuery"',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      itemCount: results.length,
      separatorBuilder: (_, __) => SizedBox(height: 1.h),
      itemBuilder: (context, index) {
        final result = results[index];
        return _SearchResultItem(
          serviceName: result['service']!,
          categoryName: result['category']!,
          onTap: () =>
              _onSearchResultTap(result['service']!, result['category']!),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final String name;
  final String iconName;
  final Color accentColor;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.iconName,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            // Slightly lighter card background with subtle gradient for depth
            gradient: LinearGradient(
              colors: _isPressed
                  ? [const Color(0xFFF0F1F5), const Color(0xFFE8EAF0)]
                  : [const Color(0xFFFFFFFF), const Color(0xFFF5F6FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: _isPressed
                  ? widget.accentColor.withValues(alpha: 0.35)
                  : widget.accentColor.withValues(alpha: 0.12),
              width: 1.0,
            ),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      spreadRadius: 0,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          padding: EdgeInsets.all(3.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon container with frosted/glass look
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withValues(alpha: 0.25),
                      widget.accentColor.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.30),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.18),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: widget.iconName,
                    color: widget.accentColor,
                    size: 28,
                  ),
                ),
              ),
              SizedBox(height: 1.4.h),
              Text(
                widget.name,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A1A2A),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final String serviceName;
  final String categoryName;
  final VoidCallback onTap;

  const _SearchResultItem({
    required this.serviceName,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _neonBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'build_circle',
                  color: _neonBlue,
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    serviceName,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF1A1A2A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    categoryName,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
