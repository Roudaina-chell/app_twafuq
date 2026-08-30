// services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    // 1. نتأكدوا بلي GPS تاع الهاتف خدام
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return null;
    }

    // 2. نشوفو Permission
    LocationPermission permission = await Geolocator.checkPermission();

    // 3. إذا ما عطاش permission، نطلبوه
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    // 4. إذا رفض permission
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    // 5. نجيب الموقع
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }
}
