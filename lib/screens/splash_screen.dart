// screens/splash_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding/onboarding_screen.dart';
import 'legal/legal_screen.dart';
import '../pages/location_check_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // هوية بصرية متناسقة مع باقي التطبيق (نفس ألوان الأونبواردينغ)
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  // ✅ كنترولر الدخول (staggered entrance)
  late final AnimationController _controller;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _loaderFade;

  // ✅ كنترولر الحركة المستمرة (تنفّس الشعار + الخلفية + نقاط التحميل)
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    // الشعار: أول حاجة تبان (0% -> 45%)
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    // اسم التطبيق: يبان من بعد الشعار (25% -> 65%)
    _titleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // الخط الذهبي الصغير الفاصل (40% -> 70%)
    _dividerWidth = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    // الشعار الفرعي: يبان من بعد العنوان (45% -> 85%)
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
      ),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // مؤشر التحميل: آخر حاجة تبان (70% -> 100%)
    _loaderFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.70, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    // ✅ أولاً نتحققو من المستخدم المسجل
    final user = FirebaseAuth.instance.currentUser;

    // إذا كان مسجل الدخول، نروحو مباشرة لـ LocationCheckPage
    // (وهي اللي رح تتحقق من اكتمال الملف وتوجه للـ Home أو تكمل الإنشاء)
    if (user != null) {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationCheckPage()),
      );
      return;
    }

    // باقي الكود القديم للمستخدمين غير المسجلين
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    final acceptedLegal = prefs.getBool('hasAcceptedLegal') ?? false;

    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    if (!seenOnboarding) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else if (!acceptedLegal) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LegalScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LocationCheckPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  // خلفية متدرجة + دوائر ضبابية متحركة بهدوء
  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final t = _ambientController.value;
        return Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(bg, Colors.white, 0.4)!,
                      bg,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -80 + (t * 16),
              left: -70,
              child: _blurCircle(220, gold.withValues(alpha: 0.10)),
            ),
            Positioned(
              bottom: -90 - (t * 14),
              right: -60,
              child: _blurCircle(240, darkGreen.withValues(alpha: 0.07)),
            ),
            Positioned(
              top: 120 - (t * 10),
              right: -40,
              child: _blurCircle(120, gold.withValues(alpha: 0.06)),
            ),
          ],
        );
      },
    );
  }

  Widget _blurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  // حلقات زخرفية دوّارة خلف الشعار
  Widget _buildRotatingRings() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final angle = _ambientController.value * 2 * math.pi * 0.06;
        return Transform.rotate(
          angle: angle,
          child: Container(
            width: 168,
            height: 168,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withValues(alpha: 0.28),
                width: 1.1,
              ),
            ),
          ),
        );
      },
    );
  }

  // ثلاث نقاط تحميل نابضة بدل الدائرة الكلاسيكية
  Widget _buildPulsingDots() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final shifted = (_ambientController.value + (index * 0.25)) % 1.0;
            final scale = 0.55 + (0.45 * (0.5 - (shifted - 0.5).abs()) * 2);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.75),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAmbientBackground()),
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_controller, _ambientController]),
              builder: (context, _) {
                // نبضة تنفّس خفيفة على الشعار بعد انتهاء الدخول
                final breathe = 1 +
                    (_controller.isCompleted
                        ? (_ambientController.value * 0.03)
                        : 0.0);

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ==================================================
                    // الشعار — مع حلقة دوّارة وتوهّج خفيف
                    // ==================================================
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Transform.scale(
                          scale: breathe,
                          child: SizedBox(
                            width: 168,
                            height: 168,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildRotatingRings(),
                                Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: darkGreen.withValues(alpha: 0.14),
                                        blurRadius: 30,
                                        offset: const Offset(0, 14),
                                      ),
                                      BoxShadow(
                                        color: gold.withValues(alpha: 0.10),
                                        blurRadius: 14,
                                        offset: const Offset(0, -4),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Image.asset(
                                    'assets/images/logo_tawafuq.png',
                                    width: 92,
                                    height: 92,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ==================================================
                    // اسم التطبيق — يبان بعد الشعار
                    // ==================================================
                    ClipRect(
                      child: FadeTransition(
                        opacity: _titleFade,
                        child: SlideTransition(
                          position: _titleSlide,
                          child: ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [darkGreen, Color(0xFF1E6B4E)],
                            ).createShader(bounds),
                            child: const Text(
                              'PactWed',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ==================================================
                    // خط ذهبي صغير فاصل — يتمدد تدريجياً
                    // ==================================================
                    AnimatedBuilder(
                      animation: _dividerWidth,
                      builder: (context, _) {
                        return SizedBox(
                          width: 46,
                          height: 3,
                          child: Align(
                            alignment: Alignment.center,
                            child: FractionallySizedBox(
                              widthFactor: _dividerWidth.value,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      gold.withValues(alpha: 0.15),
                                      gold,
                                      gold.withValues(alpha: 0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // ==================================================
                    // الشعار الفرعي — يبان بعد العنوان
                    // ==================================================
                    ClipRect(
                      child: FadeTransition(
                        opacity: _subtitleFade,
                        child: SlideTransition(
                          position: _subtitleSlide,
                          child: Text(
                            'توافقك الحقيقي',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 14.5,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 64),

                    // ==================================================
                    // مؤشر تحميل — نقاط نابضة أنيقة بدل الدائرة الكلاسيكية
                    // ==================================================
                    FadeTransition(
                      opacity: _loaderFade,
                      child: _buildPulsingDots(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}