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
  static const Color bg = Color(0xFFFAF7F2);

  bool _loading = false;
  String? _errorMessage;

  final List<String> _supportedCities = [
    'الجزائر العاصمة',
    'البليدة',
    'قسنطينة',
    'قالمة',
  ];

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

    // 🔍 DEBUG: on affiche la position exacte reçue du GPS
    // ignore: avoid_print
    print(
      '📍 Position reçue: lat=${result.latitude}, lng=${result.longitude}, accuracy=${result.accuracy}m',
    );

    // ✅ حساب مباشر بالإحداثيات، بلا reverse geocoding
    final bool allowed = LocationService.isLocationAllowed(
      result.latitude,
      result.longitude,
    );

    // 🔍 DEBUG: on affiche le résultat du matching + la distance à chaque wilaya
    // ignore: avoid_print
    print('📍 Autorisé: $allowed');
    for (final zone in LocationService.allowedWilayas) {
      final double d = Geolocator.distanceBetween(
        result.latitude,
        result.longitude,
        zone.lat,
        zone.lng,
      );
      // ignore: avoid_print
      print(
        '   → ${zone.name}: distance=${d.toStringAsFixed(0)}m (limite=${zone.radiusMeters}m)',
      );
    }

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

  void _showWhyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.help_outline, color: darkGreen),
            const SizedBox(width: 10),
            const Text(
              'لماذا نطلب الموقع؟',
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'نطلب موقعك لعرض أقرب المتوافقين إليك في منطقتك، ولتوفير تجربة مخصصة بناءً على مدينتك. نحن نلتزم بحماية خصوصيتك ولا نشارك موقعك مع أي طرف ثالث.',
          style: TextStyle(height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: darkGreen),
            child: const Text('فهمت'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ============================================================
              // ✅ ويدجت الخريطة الجديد (Pin + خريطة مرسومة + بيضاوي النطاق)
              // ============================================================
              const _MapPinWidget(),
              const SizedBox(height: 28),
              const Text(
                'تأكيد موقعك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'تحتاج للتأكد من وجودك في إحدى الولايات المدعومة للخدمة.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.6),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: _supportedCities.map((city) {
                  return Chip(
                    label: Text(
                      city,
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: gold.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    avatar: const Icon(
                      Icons.location_city,
                      color: gold,
                      size: 18,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تأكيد الموقع',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _showWhyDialog,
                child: const Text(
                  'لماذا نطلب الموقع؟',
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final bool isActive = index == 0;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive ? gold : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ✅ ويدجت الخريطة (صورة ثابتة جاهزة)
// ============================================================
class _MapPinWidget extends StatelessWidget {
  const _MapPinWidget();

  static const Color darkGreen = Color(0xFF0F3D2E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 170,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Image.asset(
          'assets/images/location_map.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) {
            debugPrint('❌ location_map.png load failed: $error');
            return Container(
              color: const Color(0xFFF2EFE9),
              alignment: Alignment.center,
              child: const Icon(
                Icons.location_on_rounded,
                color: darkGreen,
                size: 40,
              ),
            );
          },
        ),
      ),
    );
  }
}
