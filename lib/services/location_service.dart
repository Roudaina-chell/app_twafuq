// services/location_service.dart
import 'package:geolocator/geolocator.dart';

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ============================================================
  // ✅ الولايات المسموحة: مركز كل ولاية (lat, lng) + شعاع بالمتر
  // الشعاع محسوب باش يغطي حدود الولاية تقريبا (مساحة الولاية)
  // عدّل هاد القيم إلا حبيت تدق أكثر على الحدود الحقيقية
  // ============================================================
  static const List<WilayaZone> allowedWilayas = [
    WilayaZone(
      name: 'الجزائر العاصمة',
      lat: 36.7538,
      lng: 3.0588,
      radiusMeters: 35000,
    ),
    WilayaZone(name: 'البليدة', lat: 36.4700, lng: 2.8280, radiusMeters: 30000),
    WilayaZone(name: 'قسنطينة', lat: 36.3650, lng: 6.6147, radiusMeters: 30000),
    WilayaZone(name: 'قالمة', lat: 36.4621, lng: 7.4263, radiusMeters: 40000),
  ];

  // ============================================================
  // ✅ تتحقق واش الإحداثيات المعطاة داخل شعاع وحدة من الولايات
  // المسموحة، بلا ما تحتاج أي reverse geocoding (لا نتوورك زايد
  // ولا مشكل لغة فالمقارنة)
  // ============================================================
  static bool isLocationAllowed(double latitude, double longitude) {
    return matchedWilaya(latitude, longitude) != null;
  }

  // ترجع اسم الولاية المطابقة (أو null إلا ماكانش تطابق)
  // مفيدة للعرض فالواجهة أو للـ debug
  static WilayaZone? matchedWilaya(double latitude, double longitude) {
    for (final zone in allowedWilayas) {
      final double distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        zone.lat,
        zone.lng,
      );
      if (distance <= zone.radiusMeters) {
        return zone;
      }
    }
    return null;
  }
}

class WilayaZone {
  final String name;
  final double lat;
  final double lng;
  final double radiusMeters;

  const WilayaZone({
    required this.name,
    required this.lat,
    required this.lng,
    required this.radiusMeters,
  });
}
