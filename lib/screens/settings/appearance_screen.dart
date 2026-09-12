// screens/settings/appearance_screen.dart
//
// ✅ شاشة "المظهر" — دابا كتستعمل Theme.of(context) بدل الألوان
// الثابتة (darkGreen/gold/bg كانو hardcoded بحال الوضع النهاري
// دائما). هاذشي هو السبب اللي كان خلي الشاشة (وكل الشاشات الأخرى)
// ما كتبدلش شكلها حتى ولو AppThemeController.themeMode تبدل فعليا:
// MaterialApp كيبدل الثيم، لكن أي Container/Text بلون ثابت
// (const Color) ما عندوش علاقة بالثيم — خاصو يقرا Theme.of(context).
//
// ⚠️ باش الوضع الليلي يبان فـ كامل التطبيق، خاص نفس التغيير (قراءة
// Theme.of(context) بدل الألوان الثابتة) يتدار فـ باقي الشاشات
// (profile_edit_screen.dart، privacy_settings_screen.dart...).

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppAppearanceMode { day, night }

// ================================================================
// ✅ AppThemeController: مصدر وحيد للحقيقة لوضع الثيم الحالي.
// ================================================================
class AppThemeController {
  AppThemeController._();

  static const String prefsModeKey = 'appearance_mode'; // 'day' | 'night'

  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(prefsModeKey);
      themeMode.value = saved == 'night' ? ThemeMode.dark : ThemeMode.light;
    } catch (e) {
      debugPrint('❌ AppThemeController.load failed: $e');
    }
  }

  static Future<void> setMode(AppAppearanceMode mode) async {
    final newMode = mode == AppAppearanceMode.night
        ? ThemeMode.dark
        : ThemeMode.light;
    themeMode.value = newMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        prefsModeKey,
        mode == AppAppearanceMode.night ? 'night' : 'day',
      );
    } catch (e) {
      debugPrint('❌ AppThemeController.setMode save failed: $e');
    }
  }
}

class AppearanceScreen extends StatefulWidget {
  const AppearanceScreen({super.key});

  @override
  State<AppearanceScreen> createState() => _AppearanceScreenState();
}

class _AppearanceScreenState extends State<AppearanceScreen> {
  static const String _prefsAutoKey = 'appearance_auto_switch';

  AppAppearanceMode _selectedMode = AppAppearanceMode.day;
  bool _autoSwitch = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      await AppThemeController.load();
      final prefs = await SharedPreferences.getInstance();
      final savedAuto = prefs.getBool(_prefsAutoKey);
      if (!mounted) return;
      setState(() {
        _selectedMode = AppThemeController.themeMode.value == ThemeMode.dark
            ? AppAppearanceMode.night
            : AppAppearanceMode.day;
        _autoSwitch = savedAuto ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Appearance: prefs load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectMode(AppAppearanceMode mode) async {
    setState(() => _selectedMode = mode);
    await AppThemeController.setMode(mode);
  }

  Future<void> _toggleAuto(bool value) async {
    setState(() => _autoSwitch = value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsAutoKey, value);
    } catch (e) {
      debugPrint('❌ Appearance: save auto-switch failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ نقراو الألوان من الثيم الحالي (نهاري أو ليلي) بدل ما نثبتهم.
    // هاذشي هو اللي كيخلي الصفحة تبدل شكلها فعليا مع الوضع الليلي.
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darkGreen = scheme.primary;
    final gold = scheme.secondary;
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = scheme.surface;
    final subtitleColor = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: darkGreen))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                children: [
                  _buildHeader(context, darkGreen, gold, subtitleColor),
                  const SizedBox(height: 22),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildModeCard(
                          mode: AppAppearanceMode.day,
                          title: 'الوضع النهاري',
                          subtitle: 'مناسب للاستخدام في\nالإضاءة العالية',
                          icon: Icons.wb_sunny_rounded,
                          cardBg: const Color(0xFFFAF7F2),
                          statusBarDark: true,
                          darkGreen: darkGreen,
                          gold: gold,
                          cardColor: cardColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildModeCard(
                          mode: AppAppearanceMode.night,
                          title: 'الوضع الليلي',
                          subtitle: 'مريح للعين ويقلل من\nإجهاد الشاشة',
                          icon: Icons.nightlight_round,
                          cardBg: const Color(0xFF0F3D2E),
                          statusBarDark: false,
                          darkGreen: darkGreen,
                          gold: gold,
                          cardColor: cardColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildAutoSwitchTile(darkGreen, cardColor, subtitleColor),
                  const SizedBox(height: 14),
                  _buildInfoBanner(darkGreen, cardColor, subtitleColor),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // 🔝 الهيدر: سهم رجوع + عنوان "المظهر" فـ الوسط + وصف قصير
  // ============================================================
  Widget _buildHeader(
    BuildContext context,
    Color darkGreen,
    Color gold,
    Color subtitleColor,
  ) {
    return Column(
      children: [
        SizedBox(
          height: 44,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: darkGreen,
                  size: 24,
                ),
                splashRadius: 22,
                onPressed: () => Navigator.maybePop(context),
              ),
              Expanded(
                child: ShaderMask(
                  shaderCallback: (rect) => LinearGradient(
                    colors: [darkGreen, gold],
                  ).createShader(rect),
                  child: const Text(
                    'المظهر',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'اختر المظهر الذي يناسبك',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: subtitleColor),
        ),
      ],
    );
  }

  // ============================================================
  // 🃏 كارت اختيار وضع (نهاري/ليلي)
  // ============================================================
  Widget _buildModeCard({
    required AppAppearanceMode mode,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBg,
    required bool statusBarDark,
    required Color darkGreen,
    required Color gold,
    required Color cardColor,
  }) {
    final bool selected = _selectedMode == mode;
    final Color textOnCard = statusBarDark ? darkGreen : Colors.white;

    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? gold : Colors.grey.shade400.withValues(alpha: 0.4),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                _buildPhonePreview(
                  cardBg: cardBg,
                  textOnCard: textOnCard,
                  gold: gold,
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: selected
                          ? LinearGradient(colors: [gold, darkGreen])
                          : null,
                      border: Border.all(
                        color: selected ? Colors.transparent : Colors.grey.shade400,
                        width: 1.4,
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [gold.withValues(alpha: 0.22), darkGreen.withValues(alpha: 0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: darkGreen, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.35,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 📱 معاينة مصغرة لواجهة الهاتف داخل الكارت — بقات ثابتة عمدا
  // (كتوري شكل النهاري/الليلي بحال هوما، بصح فـ الواقع)
  // ============================================================
  Widget _buildPhonePreview({
    required Color cardBg,
    required Color textOnCard,
    required Color gold,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 120,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(color: cardBg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: gold.withValues(alpha: 0.85),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _previewLine(textOnCard, widthFactor: 0.35, filled: true),
            const SizedBox(height: 8),
            for (int i = 0; i < 3; i++) ...[
              _previewRow(textOnCard),
              const SizedBox(height: 5),
            ],
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                4,
                (_) => Icon(
                  Icons.circle,
                  size: 5,
                  color: textOnCard.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewLine(
    Color color, {
    double widthFactor = 1,
    bool filled = false,
  }) {
    return FractionallySizedBox(
      alignment: Alignment.centerRight,
      widthFactor: widthFactor,
      child: Container(
        height: 6,
        decoration: BoxDecoration(
          color: color.withValues(alpha: filled ? 0.35 : 0.18),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _previewRow(Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _previewLine(color, widthFactor: 1, filled: false)),
      ],
    );
  }

  // ============================================================
  // 🔁 كارت "التبديل التلقائي"
  // ============================================================
  Widget _buildAutoSwitchTile(
    Color darkGreen,
    Color cardColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: darkGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: darkGreen.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.wb_sunny_rounded, color: darkGreen, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'التبديل التلقائي',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'يتغير المظهر تلقائياً حسب الوقت',
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
              ],
            ),
          ),
          Switch(
            value: _autoSwitch,
            onChanged: _toggleAuto,
            activeThumbColor: Colors.white,
            activeTrackColor: darkGreen,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ℹ️ بانر معلومة أسفل الشاشة
  // ============================================================
  Widget _buildInfoBanner(
    Color darkGreen,
    Color cardColor,
    Color subtitleColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: darkGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'يمكنك تغيير المظهر في أي وقت من إعدادات التطبيق.',
              style: TextStyle(fontSize: 12, color: subtitleColor),
            ),
          ),
        ],
      ),
    );
  }
}