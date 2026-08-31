// screens/profile/success_screen.dart
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

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
              const Text(
                'تم إنشاء حسابك بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 32),

              // --- اللوغو + الكونفيتي ---
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // شرارات الكونفيتي حوالين اللوغو
                    const Positioned(
                      top: 18,
                      left: 60,
                      child: _ConfettiDot(color: Color(0xFFE85D75), size: 8),
                    ),
                    const Positioned(
                      top: 6,
                      right: 90,
                      child: _ConfettiDot(color: gold, size: 6),
                    ),
                    const Positioned(
                      top: 40,
                      right: 30,
                      child: _ConfettiPiece(
                        color: Color(0xFFF2A93B),
                        angle: 0.6,
                      ),
                    ),
                    const Positioned(
                      bottom: 55,
                      right: 40,
                      child: _ConfettiPiece(
                        color: Color(0xFFE85D75),
                        angle: -0.4,
                      ),
                    ),
                    const Positioned(
                      bottom: 30,
                      left: 40,
                      child: _ConfettiDot(color: gold, size: 7),
                    ),
                    const Positioned(
                      bottom: 70,
                      left: 20,
                      child: _ConfettiPiece(
                        color: Color(0xFFF2A93B),
                        angle: 1.1,
                      ),
                    ),
                    const Positioned(
                      top: 70,
                      left: 15,
                      child: _ConfettiDot(color: Color(0xFFE85D75), size: 5),
                    ),

                    // اللوغو الحقيقي متاع TAWAFUQ
                    // ملاحظة: خاصك تزيد الملف فـ pubspec.yaml تحت assets/images/
                    // وتتأكد أن المسار يطابق الاسم الحقيقي متاع الملف عندك
                    Image.asset(
                      'assets/images/logo_tawafuq.png',
                      width: 150,
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              const Text(
                'مرحباً بك في TAWAFUQ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'إبدأ رحلتك للعثور على شريك حياتك',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),

              const SizedBox(height: 36),
              SizedBox(
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
            ],
          ),
        ),
      ),
    );
  }
}

/// نقطة كونفيتي دائرية صغيرة
class _ConfettiDot extends StatelessWidget {
  final Color color;
  final double size;

  const _ConfettiDot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// شريطة كونفيتي مستطيلة صغيرة بميلان
class _ConfettiPiece extends StatelessWidget {
  final Color color;
  final double angle;

  const _ConfettiPiece({required this.color, required this.angle});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: 12,
        height: 5,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
