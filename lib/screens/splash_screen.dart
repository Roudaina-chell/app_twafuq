// screens/splash_screen.dart
import 'package:flutter/material.dart';
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
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // حركة ناعمة وهادئة (EaseInOut) بدلاً من ElasticOut
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.forward();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
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
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // الشعار بدون ظلال أو إطارات
                Image.asset(
                  'assets/images/logo_tawafuq.png',
                  width: 130,
                  height: 130,
                ),
                const SizedBox(height: 24),
                
                // اسم التطبيق بخط خفيف ونظيف
                const Text(
                  'PactWed',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w300, // خط خفيف
                    color: textColor,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 8),
                
                // الشعار الصغير بدون خلفية، نص رمادي فقط
                const Text(
                  'توافقك الحقيقي',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 50),
                
                // تحميل بسيط وأنيق (خط رفيع)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: subtleGold.withValues(alpha: 0.5),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}