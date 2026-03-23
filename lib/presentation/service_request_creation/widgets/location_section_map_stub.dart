// Web stub: google_maps_flutter is not supported on Flutter Web.
// These stubs prevent import errors on web builds.
import 'package:flutter/material.dart';

/// Stub for LatLng on web — returns null
dynamic buildLatLng(double lat, double lng) => null;

/// Stub for GoogleMap widget on web — returns empty widget
Widget buildMapWidget({
  dynamic center,
  required void Function(dynamic latLng, String address) onLocationSelected,
}) {
  return const SizedBox.shrink();
}
