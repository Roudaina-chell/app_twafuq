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
              // ✅ ويدجت الخريطة الجديد (Pin + خريطة مزيفة + نبض)
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
// ✅ ويدجت الخريطة + الدبوس (Modern Map Pin Widget)
// ============================================================
class _MapPinWidget extends StatefulWidget {
  const _MapPinWidget();

  @override
  State<_MapPinWidget> createState() => _MapPinWidgetState();
}

class _MapPinWidgetState extends State<_MapPinWidget>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ===== خلفية "الخريطة" المزيفة (خطوط طرق) =====
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: 200,
              height: 140,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey.shade100, Colors.grey.shade200],
                ),
              ),
              child: CustomPaint(
                size: const Size(200, 140),
                painter: _FakeMapPainter(),
              ),
            ),
          ),

          // ===== دوائر النبض (Pulse rings) =====
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final double t = _pulseController.value;
              return Container(
                width: 40 + (t * 70),
                height: 40 + (t * 70),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: darkGreen.withValues(alpha: (1 - t) * 0.15),
                  border: Border.all(
                    color: darkGreen.withValues(alpha: (1 - t) * 0.4),
                    width: 1.5,
                  ),
                ),
              );
            },
          ),

          // ===== دائرة النطاق الثابتة =====
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: darkGreen.withValues(alpha: 0.10),
              border: Border.all(
                color: darkGreen.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
          ),

          // ===== الدبوس (Pin) =====
          Positioned(
            bottom: 68,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2E7D5E), darkGreen],
                  ),
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),

          // ===== نقطة صغيرة تحت الدبوس (مركز الموقع) =====
          Positioned(
            bottom: 66,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold,
                boxShadow: [
                  BoxShadow(color: gold.withValues(alpha: 0.6), blurRadius: 6),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// رسم خطوط طرق بسيطة لمحاكاة الخريطة (خلفية زخرفية فقط)
// ============================================================
class _FakeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint roadPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint thinRoadPaint = Paint()
      ..color = Colors.grey.shade300.withValues(alpha: 0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // خطوط أفقية غير منتظمة
    canvas.drawLine(
      Offset(0, size.height * 0.25),
      Offset(size.width, size.height * 0.2),
      thinRoadPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.75),
      Offset(size.width, size.height * 0.8),
      roadPaint,
    );

    // خطوط عمودية/مائلة
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.15, size.height),
      thinRoadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.78, size.height),
      roadPaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.5, size.height),
      thinRoadPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
