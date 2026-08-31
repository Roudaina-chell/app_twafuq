// pages/location_check_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../screens/profile/gender_selection_screen.dart';

class LocationCheckPage extends StatefulWidget {
  const LocationCheckPage({super.key});

  @override
  State<LocationCheckPage> createState() => _LocationCheckPageState();
}

class _LocationCheckPageState extends State<LocationCheckPage> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  bool _loading = false;
  String? _errorMessage;

  Future<void> _requestLocation() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final Position? result = await LocationService.getCurrentLocation();

    if (!mounted) return;

    if (result == null) {
      setState(() {
        _loading = false;
        _errorMessage =
            'ماقدرناش نوصلو لموقعك. تأكد من تفعيل GPS ومنح الإذن للتطبيق من إعدادات الهاتف.';
      });
      return;
    }

    final bool allowed = await LocationService.isLocationAllowed(
      result.latitude,
      result.longitude,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
    });

    if (!allowed) {
      setState(() {
        _errorMessage =
            'عذراً، التطبيق متاح حالياً فقط في الجزائر العاصمة، البليدة، قسنطينة، وقالمة. سيتم إضافة ولايات أخرى قريباً إن شاء الله.';
      });
      return;
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GenderSelectionScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkGreen.withValues(alpha: 0.08),
                  border: Border.all(color: gold, width: 2),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: darkGreen,
                  size: 52,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'الموقع الجغرافي',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'نحتاج إلى الوصول لموقعك لعرض أقرب المتوافقين إليك في منطقتك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.6),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'منح الإذن الآن',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
