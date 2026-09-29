// screens/profile/preferences_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'about_you_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  RangeValues _ageRange = const RangeValues(22, 35);
  double _maxDistance = 50;
  String? _preferredWilaya;
  bool _isSubmitting = false;
  String? _errorMessage;

  // ============================================================
  // 👤 هذه الخطوة (تفضيلات البحث) خاصة بالرجل فقط — والغرض منها
  // تحديد الملفات التي تظهر للمستخدم ضمن الاقتراحات. لا تملك
  // المرأة تفضيلات بحث في هذا التطبيق، لذلك إن كانت المستخدمة
  // امرأة يتم تجاوز هذه الخطوة مباشرة إلى AboutYouScreen دون
  // عرض النموذج.
  // ============================================================
  bool _checkingGender = true;

  // كنترولر الدخول المتدرّج (staggered)
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _iconScale;
  late final Animation<double> _cardsFade;
  late final Animation<Offset> _cardsSlide;
  late final Animation<double> _buttonFade;

  // كنترولر الحركة المستمرة للخلفية
  late final AnimationController _ambientController;

  final List<String> _wilayas = const [
    'بدون تفضيل',
    'الجزائر العاصمة',
    'البليدة',
    'بومرداس',
    'تيبازة',
    'وهران',
    'قسنطينة',
    'عنابة',
  ];

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _iconScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _cardsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOut),
    );
    _cardsSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _checkGenderAndProceed();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _checkGenderAndProceed() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        if (mounted) setState(() => _checkingGender = false);
        _entranceController.forward();
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final gender = (doc.data()?['gender'] as String?)?.toLowerCase();

      if (gender == 'female') {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AboutYouScreen()),
          (route) => false,
        );
        return;
      }

      if (mounted) setState(() => _checkingGender = false);
      _entranceController.forward();
    } catch (e) {
      // في حال فشل التحقق، من الأنسب عرض النموذج بدلاً من إيقاف المستخدم.
      if (mounted) setState(() => _checkingGender = false);
      _entranceController.forward();
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: لا يوجد مستخدم مسجّل الدخول';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'preferences': {
          'ageMin': _ageRange.start.round(),
          'ageMax': _ageRange.end.round(),
          'maxDistanceKm': _maxDistance.round(),
          'preferredWilaya':
              (_preferredWilaya == null || _preferredWilaya == 'بدون تفضيل')
              ? null
              : _preferredWilaya,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AboutYouScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ، يرجى المحاولة مرة أخرى';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // خلفية بدوائر ضبابية متحركة بهدوء (نفس هوية بقية الشاشات)
  Widget _buildAmbientBackground() {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, _) {
        final t = _ambientController.value;
        return Stack(
          children: [
            Positioned(
              top: -70 + (t * 14),
              right: -60,
              child: _blurCircle(190, gold.withValues(alpha: 0.09)),
            ),
            Positioned(
              bottom: -100 - (t * 12),
              left: -70,
              child: _blurCircle(220, darkGreen.withValues(alpha: 0.06)),
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
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkGreen.withValues(alpha: 0.7),
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
    if (_checkingGender) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: _buildPulsingDots()),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAmbientBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  FadeTransition(
                    opacity: _headerFade,
                    child: Row(
                      children: [
                        _PressableScale(
                          onTap: () => Navigator.maybePop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: darkGreen.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: darkGreen,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'TAWAFUQ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkGreen,
                            letterSpacing: 1,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, v, _) =>
                                  LinearProgressIndicator(
                                    value: v,
                                    minHeight: 7,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          gold,
                                        ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ICON
                  // ==================================================
                  ScaleTransition(
                    scale: _iconScale,
                    child: Center(
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              gold.withValues(alpha: 0.20),
                              gold.withValues(alpha: 0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.10),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.tune_rounded,
                          color: darkGreen,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FadeTransition(
                    opacity: _headerFade,
                    child: const Column(
                      children: [
                        Text(
                          'حدّد تفضيلاتك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'تساعدنا هذه المعلومات في اقتراح الملفات الشخصية المناسبة لك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black45,
                            fontSize: 13.5,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  FadeTransition(
                    opacity: _cardsFade,
                    child: SlideTransition(
                      position: _cardsSlide,
                      child: Column(
                        children: [
                          // بطاقة نطاق العمر
                          _PreferenceCard(
                            icon: Icons.cake_outlined,
                            title: 'الفئة العمرية',
                            trailing:
                                '${_ageRange.start.round()} - ${_ageRange.end.round()} سنة',
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 5,
                                rangeThumbShape:
                                    const RoundRangeSliderThumbShape(
                                      enabledThumbRadius: 9,
                                      elevation: 3,
                                    ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18,
                                ),
                                activeTrackColor: darkGreen,
                                inactiveTrackColor: darkGreen.withValues(
                                  alpha: 0.12,
                                ),
                                thumbColor: darkGreen,
                                valueIndicatorColor: darkGreen,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: RangeSlider(
                                values: _ageRange,
                                min: 18,
                                max: 60,
                                divisions: 42,
                                labels: RangeLabels(
                                  _ageRange.start.round().toString(),
                                  _ageRange.end.round().toString(),
                                ),
                                onChanged: (values) {
                                  setState(() {
                                    _ageRange = values;
                                  });
                                },
                              ),
                            ),
                            footerLeft: '18',
                            footerRight: '60',
                          ),
                          const SizedBox(height: 14),

                          // بطاقة المسافة القصوى
                          _PreferenceCard(
                            icon: Icons.location_on_outlined,
                            title: 'المسافة القصوى',
                            trailing: '${_maxDistance.round()} كم',
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 5,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 9,
                                  elevation: 3,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18,
                                ),
                                activeTrackColor: darkGreen,
                                inactiveTrackColor: darkGreen.withValues(
                                  alpha: 0.12,
                                ),
                                thumbColor: darkGreen,
                                valueIndicatorColor: darkGreen,
                                valueIndicatorTextStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Slider(
                                value: _maxDistance,
                                min: 5,
                                max: 200,
                                divisions: 39,
                                label: '${_maxDistance.round()} كم',
                                onChanged: (value) {
                                  setState(() {
                                    _maxDistance = value;
                                  });
                                },
                              ),
                            ),
                            footerLeft: '5 كم',
                            footerRight: '200 كم',
                          ),
                          const SizedBox(height: 14),

                          // بطاقة الولاية المفضلة
                          _PreferenceCard(
                            icon: Icons.map_outlined,
                            title: 'الولاية المفضلة',
                            child: DropdownButtonFormField<String>(
                              initialValue: _preferredWilaya ?? 'بدون تفضيل',
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: darkGreen,
                              ),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              decoration: InputDecoration(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                filled: true,
                                fillColor: darkGreen.withValues(alpha: 0.045),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: gold.withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 14,
                                color: darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              items: _wilayas
                                  .map(
                                    (w) => DropdownMenuItem<String>(
                                      value: w,
                                      child: Text(
                                        w,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _preferredWilaya = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _errorMessage != null
                        ? Container(
                            key: const ValueKey('err'),
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFDE3B40,
                              ).withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(
                                  0xFFDE3B40,
                                ).withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Color(0xFFDE3B40),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFFDE3B40),
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox(key: ValueKey('noerr'), height: 0),
                  ),

                  const SizedBox(height: 26),

                  FadeTransition(
                    opacity: _buttonFade,
                    child: _PressableScale(
                      onTap: _isSubmitting ? null : _submit,
                      minScale: 0.97,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [darkGreen, Color(0xFF165C43)],
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'إنهاء',
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FadeTransition(
                    opacity: _buttonFade,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: darkGreen,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'يمكنك تعديل هذه التفضيلات في أي وقت من إعدادات الملف الشخصي',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;
  final String? footerLeft;
  final String? footerRight;

  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.footerLeft,
    this.footerRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: darkGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (trailing != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.85, end: 1),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  key: ValueKey(trailing),
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: gold.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      trailing!,
                      style: const TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          child,
          if (footerLeft != null && footerRight != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    footerLeft!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  Text(
                    footerRight!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ويدجت مساعد: يعطي تأثير ضغط (scale down) لأي عنصر عند اللمس
class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double minScale;

  const _PressableScale({
    required this.child,
    required this.onTap,
    this.minScale = 0.96,
  });

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  double _scale = 1;

  void _setPressed(bool pressed) {
    setState(() => _scale = pressed ? widget.minScale : 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapUp: widget.onTap == null ? null : (_) => _setPressed(false),
      onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
