// screens/profile/about_you_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'profile_preview_screen.dart';

class AboutYouScreen extends StatefulWidget {
  const AboutYouScreen({super.key});

  @override
  State<AboutYouScreen> createState() => _AboutYouScreenState();
}

class _AboutYouScreenState extends State<AboutYouScreen>
    with TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);
  static const int _maxLength = 250;
  static const int _maxInterests = 6;

  final TextEditingController _bioController = TextEditingController();
  final FocusNode _bioFocusNode = FocusNode();
  bool _isSubmitting = false;
  String? _errorMessage;

  // ✅ قائمة الاهتمامات مع أيقونة مناسبة لكل واحدة
  final List<_InterestItem> _allInterests = const [
    _InterestItem('القراءة', Icons.menu_book_rounded),
    _InterestItem('السفر', Icons.flight_rounded),
    _InterestItem('الرياضة', Icons.fitness_center_rounded),
    _InterestItem('الطبخ', Icons.restaurant_rounded),
    _InterestItem('الموسيقى', Icons.music_note_rounded),
    _InterestItem('السينما', Icons.movie_rounded),
    _InterestItem('التصوير', Icons.camera_alt_rounded),
    _InterestItem('الفن', Icons.palette_rounded),
    _InterestItem('التكنولوجيا', Icons.memory_rounded),
    _InterestItem('المشي', Icons.directions_walk_rounded),
    _InterestItem('كرة القدم', Icons.sports_soccer_rounded),
    _InterestItem('اليوغا', Icons.self_improvement_rounded),
    _InterestItem('القهوة', Icons.coffee_rounded),
    _InterestItem('الألعاب', Icons.sports_esports_rounded),
    _InterestItem('الكتابة', Icons.edit_rounded),
    _InterestItem('الطبيعة', Icons.park_rounded),
  ];

  final Set<String> _selectedInterests = {};

  // كنترولر الدخول المتدرّج (staggered)
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _avatarScale;
  late final Animation<double> _bioFade;
  late final Animation<Offset> _bioSlide;
  late final Animation<double> _interestsFade;
  late final Animation<Offset> _interestsSlide;
  late final Animation<double> _buttonFade;

  // كنترولر الحركة المستمرة للخلفية
  late final AnimationController _ambientController;

  bool _bioFocused = false;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() => setState(() {}));
    _bioFocusNode.addListener(() {
      setState(() => _bioFocused = _bioFocusNode.hasFocus);
    });

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );

    _avatarScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _bioFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.60, curve: Curves.easeOut),
    );
    _bioSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.25, 0.60, curve: Curves.easeOutCubic),
          ),
        );

    _interestsFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.80, curve: Curves.easeOut),
    );
    _interestsSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.40, 0.80, curve: Curves.easeOutCubic),
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

    _entranceController.forward();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _bioFocusNode.dispose();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < _maxInterests) {
          _selectedInterests.add(interest);
        }
      }
      _errorMessage = null;
    });
  }

  Future<void> _submit() async {
    final bio = _bioController.text.trim();

    if (bio.isEmpty) {
      setState(() {
        _errorMessage = 'يرجى كتابة نبذة عنك للمتابعة';
      });
      return;
    }

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
        'bio': bio,
        'interests': _selectedInterests.toList(),
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const ProfilePreviewScreen()),
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
              child: _blurCircle(180, gold.withValues(alpha: 0.09)),
            ),
            Positioned(
              bottom: -90 - (t * 12),
              left: -70,
              child: _blurCircle(210, darkGreen.withValues(alpha: 0.06)),
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

  @override
  Widget build(BuildContext context) {
    final int currentLength = _bioController.text.characters.length;
    final bool canSubmit = _bioController.text.trim().isNotEmpty;
    final bool nearLimit = currentLength >= (_maxLength * 0.9);

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

                  // أيقونة كبيرة في المنتصف مع دخول مرن
                  ScaleTransition(
                    scale: _avatarScale,
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
                          Icons.edit_note_outlined,
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
                          'نبذة عنك',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            color: darkGreen,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'اكتب نبذة مختصرة عن نفسك واختر اهتماماتك المفضلة',
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
                  const SizedBox(height: 22),

                  // ==================================================
                  // حقل النص
                  // ==================================================
                  FadeTransition(
                    opacity: _bioFade,
                    child: SlideTransition(
                      position: _bioSlide,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: _bioFocused
                                ? darkGreen.withValues(alpha: 0.45)
                                : Colors.transparent,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(
                                alpha: _bioFocused ? 0.10 : 0.05,
                              ),
                              blurRadius: _bioFocused ? 20 : 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _bioController,
                              focusNode: _bioFocusNode,
                              maxLength: _maxLength,
                              maxLines: 5,
                              textAlign: TextAlign.right,
                              decoration: InputDecoration(
                                hintText: 'اكتب هنا...',
                                hintStyle: TextStyle(
                                  color: Colors.grey.shade400,
                                ),
                                contentPadding: const EdgeInsets.all(16),
                                border: InputBorder.none,
                                counterText: '',
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  AnimatedOpacity(
                                    duration: const Duration(milliseconds: 200),
                                    opacity: currentLength > 0 ? 1 : 0,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: darkGreen,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'تم',
                                          style: TextStyle(
                                            color: darkGreen,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      color: nearLimit
                                          ? gold
                                          : Colors.grey.shade500,
                                      fontSize: 12,
                                      fontWeight: nearLimit
                                          ? FontWeight.w700
                                          : FontWeight.w400,
                                    ),
                                    child: Text('$currentLength/$_maxLength'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // الاهتمامات
                  // ==================================================
                  FadeTransition(
                    opacity: _interestsFade,
                    child: SlideTransition(
                      position: _interestsSlide,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
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
                                  child: const Icon(
                                    Icons.favorite_border_rounded,
                                    color: darkGreen,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'اهتماماتك',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: darkGreen,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                                TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.8, end: 1),
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutBack,
                                  key: ValueKey(_selectedInterests.length),
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
                                      '${_selectedInterests.length}/$_maxInterests',
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
                            const SizedBox(height: 4),
                            Text(
                              'اختر حتى $_maxInterests اهتمامات تعبّر عنك',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 9,
                              runSpacing: 9,
                              children: _allInterests.map((item) {
                                final bool selected = _selectedInterests
                                    .contains(item.label);
                                final bool disabled =
                                    !selected &&
                                    _selectedInterests.length >= _maxInterests;

                                return _PressableScale(
                                  onTap: disabled
                                      ? null
                                      : () => _toggleInterest(item.label),
                                  minScale: 0.9,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? darkGreen
                                          : (disabled
                                                ? Colors.grey.shade100
                                                : darkGreen.withValues(
                                                    alpha: 0.05,
                                                  )),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: selected
                                            ? darkGreen
                                            : (disabled
                                                  ? Colors.grey.shade200
                                                  : gold.withValues(
                                                      alpha: 0.35,
                                                    )),
                                      ),
                                      boxShadow: selected
                                          ? [
                                              BoxShadow(
                                                color: darkGreen.withValues(
                                                  alpha: 0.25,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_rounded
                                              : item.icon,
                                          size: 15,
                                          color: selected
                                              ? Colors.white
                                              : (disabled
                                                    ? Colors.grey.shade400
                                                    : gold),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? Colors.white
                                                : (disabled
                                                      ? Colors.grey.shade400
                                                      : darkGreen),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
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

                  const SizedBox(height: 22),

                  FadeTransition(
                    opacity: _buttonFade,
                    child: _PressableScale(
                      onTap: _isSubmitting ? null : _submit,
                      minScale: 0.97,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: canSubmit
                              ? const LinearGradient(
                                  colors: [darkGreen, Color(0xFF165C43)],
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                )
                              : null,
                          color: canSubmit ? null : Colors.grey.shade300,
                          boxShadow: canSubmit
                              ? [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.28),
                                    blurRadius: 14,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'حفظ ومتابعة',
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: canSubmit
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 14,
                                      color: canSubmit
                                          ? Colors.white
                                          : Colors.grey.shade600,
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
                            'يمكنك تعديل النبذة والاهتمامات في أي وقت من إعدادات الملف الشخصي',
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

class _InterestItem {
  final String label;
  final IconData icon;
  const _InterestItem(this.label, this.icon);
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
