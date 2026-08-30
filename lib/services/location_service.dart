// services/location_service.dart
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // ============================================================
  // ✅ الولايات المسموحة (بالأسماء اللي كترجع بيها الخرائط)
  // ============================================================
  static const List<String> _allowedWilayas = [
    'Alger',
    'Algiers',
    'Blida',
    'Constantine',
  ];

  // ============================================================
  // ✅ دالة جديدة: كتاخد الإحداثيات وترجع اسم الولاية عن طريق
  // reverse geocoding، وتتحقق واش هي من الولايات المسموحة
  // ============================================================
  static Future<bool> isLocationAllowed(
    double latitude,
    double longitude,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isEmpty) return false;

      final placemark = placemarks.first;

      final String? adminArea = placemark.administrativeArea;
      final String? subAdminArea = placemark.subAdministrativeArea;

      for (final wilaya in _allowedWilayas) {
        if ((adminArea != null &&
                adminArea.toLowerCase().contains(wilaya.toLowerCase())) ||
            (subAdminArea != null &&
                subAdminArea.toLowerCase().contains(wilaya.toLowerCase()))) {
          return true;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }
}