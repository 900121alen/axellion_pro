import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _darkBg = Color(0xFFEEEFF4);

class ServiceCategoriesScreen extends StatefulWidget {
  const ServiceCategoriesScreen({super.key});

  @override
  State<ServiceCategoriesScreen> createState() =>
      _ServiceCategoriesScreenState();
}

class _ServiceCategoriesScreenState extends State<ServiceCategoriesScreen> {
  static const Map<String, List<Map<String, String>>> _categoryServices = {
    'Detailing & Car Wash': [
      {'name': 'Full Detail', 'icon': 'local_car_wash'},
      {'name': 'Exterior Wash', 'icon': 'local_car_wash'},
      {'name': 'Interior Cleaning', 'icon': 'cleaning_services'},
      {'name': 'Paint Protection', 'icon': 'shield'},
      {'name': 'Ceramic Coating', 'icon': 'auto_awesome'},
      {'name': 'Steam Cleaning', 'icon': 'water_drop'},
    ],
    'Wheel & Tire': [
      {'name': 'Wheel Repair', 'icon': 'tire_repair'},
      {'name': 'Wheel Painting', 'icon': 'format_paint'},
      {'name': 'Curb Rash Repair', 'icon': 'build'},
      {'name': 'Flat Tire Repair', 'icon': 'tire_repair'},
      {'name': 'Tire Replacement', 'icon': 'tire_repair'},
      {'name': 'Tire Rotation', 'icon': 'rotate_right'},
    ],
    'Maintenance': [
      {'name': 'Oil Change', 'icon': 'opacity'},
      {'name': 'Filter Replacement', 'icon': 'filter_alt'},
      {'name': 'Fluid Top-Up', 'icon': 'water_drop'},
      {'name': 'Spark Plug Replacement', 'icon': 'bolt'},
      {'name': 'Belt Inspection', 'icon': 'settings'},
      {'name': 'Battery Check', 'icon': 'battery_charging_full'},
    ],
    'Mechanical Issues': [
      {'name': 'Brake Repair', 'icon': 'car_crash'},
      {'name': 'Suspension Repair', 'icon': 'engineering'},
      {'name': 'Transmission Service', 'icon': 'settings'},
      {'name': 'Engine Repair', 'icon': 'engineering'},
      {'name': 'Exhaust Repair', 'icon': 'air'},
      {'name': 'Steering Repair', 'icon': 'radio_button_unchecked'},
    ],
    'Electrical': [
      {'name': 'Battery Replacement', 'icon': 'battery_charging_full'},
      {'name': 'Alternator Repair', 'icon': 'bolt'},
      {'name': 'Starter Motor', 'icon': 'power'},
      {'name': 'Wiring Repair', 'icon': 'cable'},
      {'name': 'Lighting Repair', 'icon': 'lightbulb'},
      {'name': 'Fuse Replacement', 'icon': 'electrical_services'},
    ],
    'Exterior & Body': [
      {'name': 'Dent Removal', 'icon': 'directions_car'},
      {'name': 'Paint Touch-Up', 'icon': 'format_paint'},
      {'name': 'Scratch Repair', 'icon': 'build'},
      {'name': 'Bumper Repair', 'icon': 'directions_car'},
      {'name': 'Window Tinting', 'icon': 'wb_sunny'},
      {'name': 'Windshield Repair', 'icon': 'visibility'},
    ],
    'Interior': [
      {'name': 'Seat Repair', 'icon': 'airline_seat_recline_normal'},
      {'name': 'Dashboard Repair', 'icon': 'dashboard'},
      {'name': 'Carpet Cleaning', 'icon': 'cleaning_services'},
      {'name': 'Headliner Repair', 'icon': 'weekend'},
      {'name': 'Door Panel Repair', 'icon': 'door_front'},
      {'name': 'AC Repair', 'icon': 'ac_unit'},
    ],
    'Diagnostics': [
      {'name': 'Engine Diagnostics', 'icon': 'search'},
      {'name': 'OBD Scan', 'icon': 'qr_code_scanner'},
      {'name': 'Electrical Diagnostics', 'icon': 'bolt'},
      {'name': 'Pre-Purchase Inspection', 'icon': 'fact_check'},
      {'name': 'Emissions Test', 'icon': 'air'},
      {'name': 'Full Vehicle Inspection', 'icon': 'manage_search'},
    ],
  };

  static const Map<String, Color> _categoryAccentColors = {
    'Detailing & Car Wash': Color(0xFF3A8BFF),
    'Wheel & Tire': Color(0xFF9B59B6),
    'Maintenance': Color(0xFFF39C12),
    'Mechanical Issues': Color(0xFF27AE60),
    'Electrical': Color(0xFFE74C3C),
    'Exterior & Body': Color(0xFF00BCD4),
    'Interior': Color(0xFFE91E8C),
    'Diagnostics': Color(0xFFFF9800),
  };

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments;
    final categoryName = args is String ? args : 'Services';
    final services = _categoryServices[categoryName] ?? [];
    final accentColor = _categoryAccentColors[categoryName] ?? _neonBlue;

    return Scaffold(
      backgroundColor: _darkBg,
      appBar: AppBar(
        backgroundColor: _darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A2A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          categoryName,
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1A2A),
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: 0.2,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFD0D3DC)),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.5.h),
          itemCount: services.length,
          separatorBuilder: (_, __) => SizedBox(height: 1.6.h),
          itemBuilder: (context, index) {
            final service = services[index];
            return _ServiceCard(
              serviceName: service['name'] ?? '',
              iconName: service['icon'] ?? 'build',
              categoryName: categoryName,
              accentColor: accentColor,
            );
          },
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String serviceName;
  final String iconName;
  final String categoryName;
  final Color accentColor;

  const _ServiceCard({
    required this.serviceName,
    required this.iconName,
    required this.categoryName,
    required this.accentColor,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isPressed = false;

  void _onTap() {
    Navigator.of(context).pushNamed(
      AppRoutes.serviceRequestCreation,
      arguments: {
        'name': widget.serviceName,
        'id': null,
        'price_range_text': widget.categoryName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          decoration: BoxDecoration(
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
                      color: widget.accentColor.withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 5),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.07),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Glowing icon container — same style as home category cards
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.accentColor.withValues(alpha: 0.25),
                      widget.accentColor.withValues(alpha: 0.10),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.30),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.accentColor.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomIconWidget(
                    iconName: widget.iconName,
                    color: widget.accentColor,
                    size: 24,
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.serviceName,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A1A2A),
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.1,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    SizedBox(height: 0.4.h),
                    Text(
                      widget.categoryName,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF6B7280),
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Subtle arrow indicator
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFFD0D3DC),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: const Color(0xFF5A5A7A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
