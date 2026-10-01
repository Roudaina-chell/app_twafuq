// screens/settings/language_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { arabic, french }

// محتفظ بها للتوافق مع ملفات أخرى قد تستوردها
const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

const double kSettingsBadgeSize = 84;
const double kSettingsBadgeIconSize = 36;

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  static const String _prefsKey = 'app_language';

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
    } catch (e) {
      debugPrint('خطأ فـ حفظ اللغة: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: p.primary))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        textDirection: TextDirection.ltr,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _CircleIconButton(
                            icon: Icons.arrow_back,
                            onTap: () => Navigator.maybePop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: kSettingsBadgeSize,
                          height: kSettingsBadgeSize,
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.language_rounded,
                            size: kSettingsBadgeIconSize,
                            color: p.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'اللغة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: p.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'اختر لغتك المفضلة',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: p.subtitle),
                      ),
                      const SizedBox(height: 28),
                      _LanguageTile(
                        selected: _selected == AppLanguage.arabic,
                        title: 'العربية',
                        code: 'ع',
                        onTap: () => _selectLanguage(AppLanguage.arabic),
                      ),
                      const SizedBox(height: 14),
                      _LanguageTile(
                        selected: _selected == AppLanguage.french,
                        title: 'الفرنسية',
                        code: 'FR',
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

class _LanguageTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String code;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.selected,
    required this.title,
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? p.gold.withValues(alpha: 0.35) : p.border,
              width: selected ? 1.3 : 1,
            ),
            boxShadow: p.shadow(alpha: selected ? 0.10 : 0.05),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: p.primary,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: p.primary,
                  ),
                ),
              ),
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? p.primary : null,
                  border: Border.all(
                    color: selected
                        ? Colors.transparent
                        : (p.isDark
                              ? Colors.grey.shade600
                              : Colors.grey.shade300),
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 16, color: p.onPrimary)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Material(
      color: p.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: p.shadow(alpha: 0.08, blur: 10, dy: 3),
          ),
          child: Icon(
            icon,
            color: p.primary,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ألوان مشتقة من الـ Theme الحالي (نهاري / ليلي) — خاصة بهذا الملف
// ---------------------------------------------------------------------------
class _Pal {
  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color bg;
  final Color card;
  final Color border;
  final Color subtitle;
  final Color gold;

  const _Pal._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.bg,
    required this.card,
    required this.border,
    required this.subtitle,
    required this.gold,
  });

  factory _Pal.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return _Pal._(
      isDark: isDark,
      primary: primary,
      onPrimary: theme.colorScheme.onPrimary,
      bg: theme.scaffoldBackgroundColor,
      card: theme.colorScheme.surface,
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFEFEAE2),
      subtitle: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      gold: const Color(0xFFC9A24B),
    );
  }

  /// ظلال (تُلغى في الوضع الليلي)
  List<BoxShadow>? shadow({
    double alpha = 0.06,
    double blur = 18,
    double dy = 8,
  }) {
    if (isDark) return null;
    return [
      BoxShadow(
        color: primary.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }
}
