// Mobile implementation: google_maps_flutter is fully supported on iOS/Android.
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sizer/sizer.dart';

/// Builds a real LatLng object on mobile
dynamic buildLatLng(double lat, double lng) => LatLng(lat, lng);

/// Builds a GoogleMap widget on mobile
Widget buildMapWidget({
  dynamic center,
  required void Function(dynamic latLng, String address) onLocationSelected,
}) {
  final LatLng initialCenter = (center is LatLng)
      ? center
      : const LatLng(37.7749, -122.4194);

  return _MapWidget(
    initialCenter: initialCenter,
    onLocationSelected: onLocationSelected,
  );
}

class _MapWidget extends StatefulWidget {
  final LatLng initialCenter;
  final void Function(dynamic latLng, String address) onLocationSelected;

  const _MapWidget({
    required this.initialCenter,
    required this.onLocationSelected,
  });

  @override
  State<_MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<_MapWidget> {
  late LatLng _center;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _center = widget.initialCenter;
    _markers = {
      Marker(markerId: const MarkerId('selected'), position: _center),
    };
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 25.h,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 13),
          markers: _markers,
          onMapCreated: (ctrl) => _mapController = ctrl,
          onTap: (latLng) {
            setState(() {
              _center = latLng;
              _markers = {
                Marker(markerId: const MarkerId('selected'), position: latLng),
              };
            });
            widget.onLocationSelected(
              latLng,
              'Selected Location (${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)})',
            );
          },
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
        ),
      ),
    );
  }
}
