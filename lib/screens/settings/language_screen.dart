// screens/settings/language_screen.dart
//
// ✅ شاشة "اللغة":
// سهم رجوع + إعدادات فـ الأعلى، أيقونة كرة أرضية + عنوان "اللغة"
// (Langue) + وصف قصير بجوج لغات (عربي/فرنسي)، بعدها لائحة لغات
// قابلة للاختيار (علم دائري + اسم اللغة بالعربي والفرنسي + دائرة
// اختيار).
//
// ✅ حيّدت الزخرفة (فروع الورق + اللمعات الذهبية) — دابا خلفية
// بسيطة (kBg) بحال باقي شاشات "حسابي".
//
// ✅ تعديل جديد:
// - زدت Directionality(RTL) صريحة (بحال باقي شاشات "حسابي")، وبدّلت
//   ترتيب زر الرجوع/الإعدادات فالـ Row باش زر الرجوع يولي فعليا
//   عل اليسار (وليس غير بصريا فمعاينة LTR).
//
// ⚠️ تبديل اللغة الفعلي للتطبيق (locale) مازال TODO — كنستنى نعرف
// شنو التقنية المستعملة (intl / easy_localization / حاجة أخرى) باش
// نزيدها صحيحة.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { arabic, french }

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const String _prefsKey = 'app_language'; // 'ar' | 'fr'

  AppLanguage _selected = AppLanguage.arabic;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefsKey);
      if (!mounted) return;
      setState(() {
        _selected = saved == 'fr' ? AppLanguage.french : AppLanguage.arabic;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Language: prefs load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectLanguage(AppLanguage lang) async {
    setState(() => _selected = lang);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefsKey,
        lang == AppLanguage.french ? 'fr' : 'ar',
      );
      // TODO: بدّل فعليا لغة التطبيق هنا (مثلا عبر intl / easy_localization)
      // حسب البنية ديال المشروع.
    } catch (e) {
      debugPrint('❌ Language: save failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: kDarkGreen),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: Icons.settings_outlined,
                            onTap: () {},
                          ),
                          const Spacer(),
                          _CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          color: kDarkGreen.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          size: 40,
                          color: kDarkGreen,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'اللغة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: kDarkGreen,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Langue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'اختر لغتك المفضلة  •  Choisissez votre langue préférée',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _LanguageTile(
                        selected: _selected == AppLanguage.arabic,
                        flag: const _FlagCircle(flag: _Flag.algeria),
                        titleAr: 'العربية',
                        titleFr: 'Arabe',
                        onTap: () => _selectLanguage(AppLanguage.arabic),
                      ),
                      const SizedBox(height: 14),
                      _LanguageTile(
                        selected: _selected == AppLanguage.french,
                        flag: const _FlagCircle(flag: _Flag.france),
                        titleAr: 'Français',
                        titleFr: 'Français',
                        onTap: () => _selectLanguage(AppLanguage.french),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

// ================================================================
// ✅ صف واحد للائحة اللغات: علم دائري + اسمين + دائرة اختيار
// ================================================================
class _LanguageTile extends StatelessWidget {
  final bool selected;
  final Widget flag;
  final String titleAr;
  final String titleFr;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.selected,
    required this.flag,
    required this.titleAr,
    required this.titleFr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? kGold.withValues(alpha: 0.35)
                  : Colors.black.withValues(alpha: 0.03),
              width: selected ? 1.3 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: kDarkGreen.withValues(alpha: selected ? 0.10 : 0.05),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              flag,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: kDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titleFr,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? kDarkGreen : null,
                  border: Border.all(
                    color: selected ? Colors.transparent : Colors.grey.shade300,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// ✅ علم دائري مبسط (الجزائر / فرنسا) مرسوم بـ CustomPaint
// ================================================================
enum _Flag { algeria, france }

class _FlagCircle extends StatelessWidget {
  final _Flag flag;
  const _FlagCircle({required this.flag});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomPaint(
        size: const Size(48, 48),
        painter: flag == _Flag.algeria
            ? _AlgeriaFlagPainter()
            : _FranceFlagPainter(),
      ),
    );
  }
}

class _AlgeriaFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w / 2, h),
      Paint()..color = const Color(0xFF006233),
    );
    canvas.drawRect(
      Rect.fromLTWH(w / 2, 0, w / 2, h),
      Paint()..color = Colors.white,
    );
    final center = Offset(w * 0.58, h / 2);
    final r = h * 0.22;
    final crescentPaint = Paint()..color = const Color(0xFFD21034);
    canvas.drawCircle(center, r, crescentPaint);
    canvas.drawCircle(
      Offset(center.dx + r * 0.55, center.dy),
      r * 0.82,
      Paint()..color = Colors.white,
    );
    // نجمة صغيرة بسيطة (خماسية مبسطة كدائرة صغيرة)
    canvas.drawCircle(
      Offset(center.dx + r * 0.15, center.dy),
      r * 0.28,
      crescentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FranceFlagPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final third = w / 3;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, third, h),
      Paint()..color = const Color(0xFF0055A4),
    );
    canvas.drawRect(
      Rect.fromLTWH(third, 0, third, h),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(third * 2, 0, third, h),
      Paint()..color = const Color(0xFFEF4135),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// ✅ زر دائري (رجوع / إعدادات)
// ================================================================
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kDarkGreen.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: kDarkGreen,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}