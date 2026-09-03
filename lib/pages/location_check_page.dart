// pages/location_check_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/location_service.dart';
import '../screens/profile/gender_selection_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';

class LocationCheckPage extends StatefulWidget {
  const LocationCheckPage({super.key});

  @override
  State<LocationCheckPage> createState() => _LocationCheckPageState();
}

class _LocationCheckPageState extends State<LocationCheckPage>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  bool _loading = false;
  String? _errorMessage;
  bool _isChecking = true; // ✅ جديد: باش نعرفو واش لازالنا نتحققو من الحالة

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  final List<String> _supportedCities = [
    'الجزائر العاصمة',
    'البليدة',
    'قسنطينة',
    'قالمة',
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(_fadeAnim);

    // ✅ بدل ما نبداو الأنيميشن مباشرة، نتحققو من الحالة أولاً
    _checkUserAndRoute();
  }

  // ✅ دالة جديدة باش نتحققو من المستخدم والملف الشخصي
  Future<void> _checkUserAndRoute() async {
    final user = FirebaseAuth.instance.currentUser;

    // إذا مافيش مستخدم مسجل => نروحو لـ LoginScreen
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
      return;
    }

    // عندنا مستخدم، نتحققو من Firestore واش الملف مكتمل
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();
      final bool profileConfirmed = data?['profileConfirmed'] == true;

      if (profileConfirmed) {
        // ✅ الملف مكتمل => نروحو للـ Home مباشرة
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
        return;
      }
    } catch (e) {
      // إذا صار خطأ، نكملو للصفحة العادية (نطلب الموقع)
    }

    // إذا الملف مكتملش (أو صار خطأ)، نكملو للصفحة العادية
    if (mounted) {
      setState(() {
        _isChecking = false;
      });
      _fadeController.forward(); // نبداو الأنيميشن دابا
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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

    // ignore: avoid_print
    print(
      '📍 Position reçue: lat=${result.latitude}, lng=${result.longitude}, accuracy=${result.accuracy}m',
    );

    final bool allowed = LocationService.isLocationAllowed(
      result.latitude,
      result.longitude,
    );

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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_on_rounded, color: darkGreen, size: 28),
              ),
              const SizedBox(height: 16),
              const Text(
                'لماذا نطلب الموقع؟',
                style: TextStyle(
                  color: darkGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'نطلب موقعك لعرض أقرب المتوافقين إليك في منطقتك، ولتوفير تجربة مخصصة بناءً على مدينتك. نحن نلتزم بحماية خصوصيتك ولا نشارك موقعك مع أي طرف ثالث.',
                textAlign: TextAlign.center,
                style: TextStyle(height: 1.7, fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'فهمت',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ إذا لازالنا نتحققو، نعرضو مؤشر تحميل
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(color: darkGreen),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const _MapPinWidget(),
                  const SizedBox(height: 30),
                  const Text(
                    'تأكيد موقعك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'تحتاج للتأكد من وجودك في إحدى الولايات المدعومة للخدمة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: Colors.black45,
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  _CitiesGrid(cities: _supportedCities, gold: gold, darkGreen: darkGreen),
                  const SizedBox(height: 28),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _errorMessage != null
                        ? Container(
                            key: const ValueKey('error'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            margin: const EdgeInsets.only(bottom: 18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDE3B40).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFDE3B40).withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDE3B40),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFFDE3B40),
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('empty'), height: 0),
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        disabledBackgroundColor: darkGreen.withValues(alpha: 0.6),
                        elevation: 0,
                        shadowColor: darkGreen.withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ).copyWith(
                        elevation: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.pressed) ? 0 : 6,
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.my_location_rounded,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 10),
                                Text(
                                  'تأكيد الموقع',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _showWhyDialog,
                    style: TextButton.styleFrom(
                      foregroundColor: gold,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'لماذا نطلب الموقع؟',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.info_outline_rounded, size: 16, color: gold),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final bool isActive = index == 0;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: isActive ? 26 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive ? gold : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ✅ Grid ديال المدن، أنظف وأعصري من الـ Wrap القديم
// ============================================================
class _CitiesGrid extends StatelessWidget {
  const _CitiesGrid({
    required this.cities,
    required this.gold,
    required this.darkGreen,
  });

  final List<String> cities;
  final Color gold;
  final Color darkGreen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cities.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.6,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: gold.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: darkGreen.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.location_city_rounded, color: gold, size: 16),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  cities[index],
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// ✅ ويدجت الخريطة (صورة ثابتة جاهزة) — نفس الصورة، فريم أعصري
// ============================================================
class _MapPinWidget extends StatelessWidget {
  const _MapPinWidget();

  static const Color darkGreen = Color(0xFF0F3D2E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
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
            // طبقة تدرّج خفيفة تعطي عمق بلا ما تبدل الصورة ولا الألوان
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}