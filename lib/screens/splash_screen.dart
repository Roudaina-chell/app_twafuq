// screens/splash_screen.dart
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
    with SingleTickerProviderStateMixin {
  // ألوان بسيطة وهادئة جداً
  static const Color backgroundColor = Color(0xFFFAFAFA); // أبيض ناعم
  static const Color textColor = Color(0xFF333333); // رمادي داكن أنيق
  static const Color subtleGold = Color(0xFFC9A24B); // لمسة ذهبية خفيفة فقط

  late final AnimationController _controller;

  // ✅ كل عنصر يخرج بدوره (staggered) بدل ما يخرجو كلهم فـ نفس الوقت
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subtitleSlide;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // الشعار: أول حاجة تبان (0% -> 45%)
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // خلفية بيضاء ناصعة بدون أي تدرجات لونية
      backgroundColor: backgroundColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==================================================
                // الشعار — أول عنصر يخرج
                // ==================================================
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Image.asset(
                      'assets/images/logo_tawafuq.png',
                      width: 128,
                      height: 128,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // ==================================================
                // اسم التطبيق — يبان بعد الشعار
                // ==================================================
                ClipRect(
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: SlideTransition(
                      position: _titleSlide,
                      child: const Text(
                        'PactWed',
                        style: TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.w300,
                          color: textColor,
                          letterSpacing: 3.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // ==================================================
                // خط ذهبي صغير فاصل — يتمدد تدريجياً
                // ==================================================
                SizedBox(
                  width: 40,
                  height: 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: _dividerWidth.value,
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: subtleGold.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ==================================================
                // الشعار الفرعي — يبان بعد العنوان
                // ==================================================
                ClipRect(
                  child: FadeTransition(
                    opacity: _subtitleFade,
                    child: SlideTransition(
                      position: _subtitleSlide,
                      child: const Text(
                        'توافقك الحقيقي',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 56),

                // ==================================================
                // مؤشر تحميل — آخر عنصر يبان
                // ==================================================
                FadeTransition(
                  opacity: _loaderFade,
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: subtleGold.withValues(alpha: 0.55),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}