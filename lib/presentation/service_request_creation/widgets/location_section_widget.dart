import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

import 'location_section_map_stub.dart'
    if (dart.library.io) 'location_section_map_real.dart';

const Color _neonBlue = Color(0xFF3A8BFF);
const Color _fieldBg = Color(0xFFDDE0E8);

class LocationSectionWidget extends StatefulWidget {
  final TextEditingController controller;
  final dynamic selectedLocation;
  final String selectedAddress;
  final String? error;
  final void Function(dynamic latLng, String address) onLocationSelected;

  const LocationSectionWidget({
    super.key,
    required this.controller,
    required this.selectedLocation,
    required this.selectedAddress,
    required this.error,
    required this.onLocationSelected,
  });

  @override
  State<LocationSectionWidget> createState() => _LocationSectionWidgetState();
}

class _LocationSectionWidgetState extends State<LocationSectionWidget> {
  bool _showMap = false;

  static const List<Map<String, dynamic>> _mockAddresses = [
    {
      'address': '123 Main St, San Francisco, CA 94102',
      'lat': 37.7749,
      'lng': -122.4194,
    },
    {
      'address': '456 Oak Ave, Los Angeles, CA 90001',
      'lat': 34.0522,
      'lng': -118.2437,
    },
    {
      'address': '789 Pine Rd, New York, NY 10001',
      'lat': 40.7128,
      'lng': -74.0060,
    },
    {
      'address': '321 Elm St, Chicago, IL 60601',
      'lat': 41.8781,
      'lng': -87.6298,
    },
    {
      'address': '654 Maple Dr, Houston, TX 77001',
      'lat': 29.7604,
      'lng': -95.3698,
    },
  ];

  Future<void> _useCurrentLocation() async {
    if (!kIsWeb) {
      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return;
      }
    }
    const mockAddress = 'Current Location, San Francisco, CA';
    widget.onLocationSelected(
      kIsWeb ? null : buildLatLng(37.7749, -122.4194),
      mockAddress,
    );
  }

  void _showAddressSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFF5F6FA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD0D3DC).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(4.w),
            child: const Text(
              'Select Address',
              style: TextStyle(
                color: Color(0xFF1A1A2A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ..._mockAddresses.map(
            (addr) => ListTile(
              leading: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _neonBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: _neonBlue,
                  size: 16,
                ),
              ),
              title: Text(
                addr['address'] as String,
                style: const TextStyle(color: Color(0xFF1A1A2A), fontSize: 13),
              ),
              onTap: () {
                widget.onLocationSelected(
                  kIsWeb
                      ? null
                      : buildLatLng(
                          addr['lat'] as double,
                          addr['lng'] as double,
                        ),
                  addr['address'] as String,
                );
                Navigator.pop(ctx);
              },
            ),
          ),
          SizedBox(height: 2.h),
        ],
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
              'Location',
              style: TextStyle(
                color: Color(0xFF1A1A2A),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.2.h),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                readOnly: true,
                onTap: _showAddressSuggestions,
                style: const TextStyle(color: Color(0xFF1A1A2A), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Enter service location',
                  hintStyle: TextStyle(
                    color: const Color(0xFF8888AA),
                    fontSize: 13,
                  ),
                  errorText: widget.error,
                  errorStyle: const TextStyle(color: Color(0xFFEF4444)),
                  filled: true,
                  fillColor: _fieldBg,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.5.h,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: CustomIconWidget(
                      iconName: 'location_on',
                      color: const Color(0xFF1A1A2A).withValues(alpha: 0.4),
                      size: 20,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.my_location,
                      color: _neonBlue,
                      size: 20,
                    ),
                    onPressed: _useCurrentLocation,
                    tooltip: 'Use current location',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide(color: const Color(0xFFD0D3DC)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFD0D3DC)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: _neonBlue, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: Color(0xFFEF4444),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        if (!kIsWeb)
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showMap = !_showMap),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 0.7.h,
                  ),
                  decoration: BoxDecoration(
                    color: _neonBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.0),
                    border: Border.all(color: _neonBlue.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.map, color: _neonBlue, size: 14),
                      SizedBox(width: 1.w),
                      Text(
                        _showMap ? 'Hide Map' : 'Show Map',
                        style: const TextStyle(
                          color: _neonBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        if (!kIsWeb && _showMap)
          buildMapWidget(
            center: widget.selectedLocation,
            onLocationSelected: (latLng, address) {
              widget.onLocationSelected(latLng, address);
            },
          ),
        if (kIsWeb && widget.selectedAddress.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: 0.5.h),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                SizedBox(width: 1.w),
                Expanded(
                  child: Text(
                    widget.selectedAddress,
                    style: const TextStyle(
                      color: Color(0xFF10B981),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
