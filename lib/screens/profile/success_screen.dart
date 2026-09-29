// screens/profile/success_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class SuccessScreen extends StatefulWidget {
  const SuccessScreen({super.key});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  // عنصر تحكم رئيسي للترتيب العام (fade + slide للنصوص والزر)
  late final AnimationController _mainController;

  // عنصر تحكم مخصص للوغو (bounce/scale)
  late final AnimationController _logoController;

  // عنصر تحكم مستمر لحركة الكونفيتي (تمايل وتوهج خفيف)
  late final AnimationController _confettiController;

  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final Animation<double> _welcomeFade;
  late final Animation<Offset> _welcomeSlide;

  late final Animation<double> _subtitleFade;
  late final Animation<Offset> _subtitleSlide;

  late final Animation<double> _buttonFade;
  late final Animation<Offset> _buttonSlide;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // العنوان: يظهر أول شيء
    _titleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(_titleFade);

    // اللوغو: bounce بعد العنوان بقليل
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );

    // "مرحباً بك"
    _welcomeFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.55, 0.8, curve: Curves.easeOut),
    );
    _welcomeSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_welcomeFade);

    // الوصف
    _subtitleFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.65, 0.9, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(_subtitleFade);

    // الزر
    _buttonFade = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
    );
    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(_buttonFade);

    // تشغيل السلسلة: العنوان والنصوص، مع انطلاق اللوغو بشكل متوازي بعد تأخير بسيط
    _mainController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _logoController.forward();
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _logoController.dispose();
    _confettiController.dispose();
    super.dispose();
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeTransition(
                opacity: _titleFade,
                child: SlideTransition(
                  position: _titleSlide,
                  child: const Text(
                    'تم إنشاء حسابك بنجاح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // --- اللوغو + الكونفيتي المتحرك ---
              SizedBox(
                height: 220,
                child: AnimatedBuilder(
                  animation: _confettiController,
                  builder: (context, child) {
                    final t = _confettiController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _AnimatedConfettiDot(
                          top: 18,
                          left: 60,
                          color: const Color(0xFFE85D75),
                          size: 8,
                          progress: t,
                          phase: 0.0,
                        ),
                        _AnimatedConfettiDot(
                          top: 6,
                          right: 90,
                          color: gold,
                          size: 6,
                          progress: t,
                          phase: 0.2,
                        ),
                        _AnimatedConfettiPiece(
                          top: 40,
                          right: 30,
                          color: const Color(0xFFF2A93B),
                          baseAngle: 0.6,
                          progress: t,
                          phase: 0.4,
                        ),
                        _AnimatedConfettiPiece(
                          bottom: 55,
                          right: 40,
                          color: const Color(0xFFE85D75),
                          baseAngle: -0.4,
                          progress: t,
                          phase: 0.6,
                        ),
                        _AnimatedConfettiDot(
                          bottom: 30,
                          left: 40,
                          color: gold,
                          size: 7,
                          progress: t,
                          phase: 0.75,
                        ),
                        _AnimatedConfettiPiece(
                          bottom: 70,
                          left: 20,
                          color: const Color(0xFFF2A93B),
                          baseAngle: 1.1,
                          progress: t,
                          phase: 0.15,
                        ),
                        _AnimatedConfettiDot(
                          top: 70,
                          left: 15,
                          color: const Color(0xFFE85D75),
                          size: 5,
                          progress: t,
                          phase: 0.5,
                        ),

                        // اللوغو الحقيقي متاع TAWAFUQ، بحركة bounce عند الدخول
                        // ملاحظة: خاصك تزيد الملف فـ pubspec.yaml تحت assets/images/
                        // وتتأكد أن المسار يطابق الاسم الحقيقي متاع الملف عندك
                        ScaleTransition(
                          scale: _logoScale,
                          child: FadeTransition(
                            opacity: _logoFade,
                            child: Image.asset(
                              'assets/images/logo_tawafuq.png',
                              width: 150,
                              height: 150,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),
              FadeTransition(
                opacity: _welcomeFade,
                child: SlideTransition(
                  position: _welcomeSlide,
                  child: const Text(
                    'مرحباً بك في TAWAFUQ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _subtitleFade,
                child: SlideTransition(
                  position: _subtitleSlide,
                  child: const Text(
                    'إبدأ رحلتك للعثور على شريك حياتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              ),

              const SizedBox(height: 36),
              FadeTransition(
                opacity: _buttonFade,
                child: SlideTransition(
                  position: _buttonSlide,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const HomeScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        elevation: 4,
                        shadowColor: darkGreen.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'إبدأ التصفح',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
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
}

/// نقطة كونفيتي دائرية صغيرة، تتمايل عاليًا وتخفت بشكل دوري
class _AnimatedConfettiDot extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;
  final double size;
  final double progress; // 0..1 من الـ confettiController
  final double phase; // إزاحة زمنية لكل نقطة باش ما يتحركوش بالتزامن

  const _AnimatedConfettiDot({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
    required this.size,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final localT = (progress + phase) % 1.0;
    final dy = math.sin(localT * 2 * math.pi) * 6;
    final opacity = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(localT * 2 * math.pi));

    return Positioned(
      top: top != null ? top! + dy : null,
      bottom: bottom != null ? bottom! - dy : null,
      left: left,
      right: right,
      child: Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

/// شريطة كونفيتي مستطيلة صغيرة، تدور ببطء وتتمايل
class _AnimatedConfettiPiece extends StatelessWidget {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color color;
  final double baseAngle;
  final double progress;
  final double phase;

  const _AnimatedConfettiPiece({
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.color,
    required this.baseAngle,
    required this.progress,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final localT = (progress + phase) % 1.0;
    final wobble = math.sin(localT * 2 * math.pi) * 0.35;
    final dy = math.cos(localT * 2 * math.pi) * 5;

    return Positioned(
      top: top != null ? top! + dy : null,
      bottom: bottom != null ? bottom! - dy : null,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: baseAngle + wobble,
        child: Container(
          width: 12,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
