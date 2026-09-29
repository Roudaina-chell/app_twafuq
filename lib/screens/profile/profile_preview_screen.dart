// screens/profile/profile_preview_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'success_screen.dart';

class ProfilePreviewScreen extends StatefulWidget {
  const ProfilePreviewScreen({super.key});

  @override
  State<ProfilePreviewScreen> createState() => _ProfilePreviewScreenState();
}

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen>
    with TickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _name = '';
  int? _age;
  String _job = '';
  String _city = '';
  String _educationLevel = '';
  String _bio = '';
  int? _ageMin;
  int? _ageMax;
  String _prefCity = '';
  // ✅ مسار صورة الأفاتار الحقيقية
  String? _avatarAsset;

  // كنترولر الدخول المتدرّج (staggered)
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<double> _avatarScale;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _buttonFade;

  // كنترولر الحركة المستمرة للخلفية
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
    );
    _avatarScale = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.10, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.30, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: const Interval(0.30, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _buttonFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.60, 1.0, curve: Curves.easeOut),
    );

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _loadProfile();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: لا يوجد مستخدم مسجّل الدخول';
          _isLoading = false;
        });
        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() ?? {};
      final preferences = (data['preferences'] as Map<String, dynamic>?) ?? {};

      setState(() {
        _name =
            (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
        _age = data['age'] as int?;
        _job =
            (data['occupation'] as String?) ?? (data['job'] as String?) ?? '';
        _city = (data['city'] as String?) ?? '';
        _educationLevel = (data['educationLevel'] as String?) ?? '';
        _bio = (data['bio'] as String?) ?? (data['about'] as String?) ?? '';
        _ageMin = preferences['ageMin'] as int?;
        _ageMax = preferences['ageMax'] as int?;
        _prefCity =
            (preferences['city'] as String?) ??
            (preferences['wilaya'] as String?) ??
            _city;
        // ✅ نجيبو مسار الأفاتار لي تسجل فـ avatar_selection.dart
        _avatarAsset = data['avatarAsset'] as String?;
        _isLoading = false;
      });

      _entranceController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل المعلومات';
        _isLoading = false;
      });
      _entranceController.forward();
    }
  }

  Future<void> _confirmProfile() async {
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
        'profileConfirmed': true,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SuccessScreen()),
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

  // ============================================================
  // ✅ ويدجت الأفاتار الحقيقي (صورة) بدل الأيقونة الثابتة
  // ============================================================
  Widget _buildAvatar() {
    if (_avatarAsset == null || _avatarAsset!.isEmpty) {
      return const Icon(Icons.person, color: Colors.white, size: 40);
    }
    return ClipOval(
      child: Image.asset(
        _avatarAsset!,
        width: 84,
        height: 84,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stack) {
          debugPrint('❌ Profile avatar load failed: $_avatarAsset -> $error');
          return const Icon(Icons.person, color: Colors.white, size: 40);
        },
      ),
    );
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
              left: -60,
              child: _blurCircle(190, gold.withValues(alpha: 0.09)),
            ),
            Positioned(
              bottom: -100 - (t * 12),
              right: -70,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          Positioned.fill(child: _buildAmbientBackground()),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: darkGreen),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
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
                                        color: darkGreen.withValues(
                                          alpha: 0.08,
                                        ),
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
                                          minHeight: 6,
                                          backgroundColor: Colors.grey.shade300,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(gold),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        FadeTransition(
                          opacity: _headerFade,
                          child: const Column(
                            children: [
                              Text(
                                'معاينة ملفك',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: darkGreen,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'تأكد من معلوماتك قبل الحفظ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 26),

                        // ==================================================
                        // الأفاتار البارز فوق البطاقة
                        // ==================================================
                        ScaleTransition(
                          scale: _avatarScale,
                          child: Center(
                            child: Container(
                              width: 104,
                              height: 104,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [darkGreen, const Color(0xFF1E6B4E)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: gold.withValues(alpha: 0.65),
                                  width: 2.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.28),
                                    blurRadius: 22,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(child: _buildAvatar()),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.12,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.verified_rounded,
                                        color: gold,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FadeTransition(
                          opacity: _headerFade,
                          child: Center(
                            child: Text(
                              _age != null ? '$_name، $_age' : _name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 19,
                                color: darkGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),

                        // ==================================================
                        // بطاقة المعاينة
                        // ==================================================
                        FadeTransition(
                          opacity: _cardFade,
                          child: SlideTransition(
                            position: _cardSlide,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.06),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      18,
                                      18,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: darkGreen.withValues(
                                              alpha: 0.07,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.work_outline_rounded,
                                                size: 13,
                                                color: darkGreen,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                _job.isNotEmpty ? _job : '—',
                                                style: const TextStyle(
                                                  color: darkGreen,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: gold.withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.location_on_outlined,
                                                size: 13,
                                                color: darkGreen,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                _city.isNotEmpty ? _city : '—',
                                                style: const TextStyle(
                                                  color: darkGreen,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // حول
                                  if (_bio.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        18,
                                        18,
                                        18,
                                        0,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const _SectionLabel(
                                            icon: Icons.info_outline_rounded,
                                            label: 'حول',
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _bio,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 14,
                                              height: 1.6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      18,
                                      18,
                                      8,
                                    ),
                                    child: Divider(
                                      color: Colors.grey.shade100,
                                      height: 1,
                                    ),
                                  ),

                                  // التفضيلات
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      18,
                                      6,
                                      18,
                                      18,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _SectionLabel(
                                          icon: Icons.tune_rounded,
                                          label: 'التفضيلات',
                                        ),
                                        const SizedBox(height: 12),
                                        _InfoRow(
                                          icon: Icons.cake_outlined,
                                          label: 'العمر',
                                          value:
                                              (_ageMin != null &&
                                                  _ageMax != null)
                                              ? '$_ageMin - $_ageMax سنة'
                                              : '${_age ?? '—'}',
                                        ),
                                        const SizedBox(height: 12),
                                        _InfoRow(
                                          icon: Icons.map_outlined,
                                          label: 'الولاية',
                                          value: _prefCity.isNotEmpty
                                              ? _prefCity
                                              : '—',
                                        ),
                                        const SizedBox(height: 12),
                                        _InfoRow(
                                          icon: Icons.school_outlined,
                                          label: 'المستوى التعليمي',
                                          value: _educationLevel.isNotEmpty
                                              ? _educationLevel
                                              : '—',
                                        ),
                                      ],
                                    ),
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
                              : const SizedBox(
                                  key: ValueKey('noerr'),
                                  height: 0,
                                ),
                        ),

                        const SizedBox(height: 24),

                        FadeTransition(
                          opacity: _buttonFade,
                          child: _PressableScale(
                            onTap: _isSubmitting ? null : _confirmProfile,
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'حفظ الملف',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(
                                            Icons.arrow_back_ios_new_rounded,
                                            size: 14,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
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

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _ProfilePreviewScreenState.darkGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 14,
            color: _ProfilePreviewScreenState.darkGreen,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: _ProfilePreviewScreenState.darkGreen,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: _ProfilePreviewScreenState.darkGreen,
          ),
        ),
      ],
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
