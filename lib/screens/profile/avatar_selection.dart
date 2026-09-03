import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'about_you_screen.dart';
import 'preferences_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String? gender;

  const AvatarSelectionScreen({
    super.key,
    this.gender,
  });

  @override
  State<AvatarSelectionScreen> createState() =>
      _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  String? _gender;
  bool _isLoadingGender = true;

  int? _selectedIndex;
  bool _isSubmitting = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // ============================================================
  // FEMALE AVATARS
  // ============================================================

  final List<_AvatarOption> _femaleAvatars = const [
    _AvatarOption(
      id: 'f_1',
      assetPath: 'assets/avatars/female/female_1.png',
      bgColor: Color(0xFFFCE4EC),
    ),
    _AvatarOption(
      id: 'f_2',
      assetPath: 'assets/avatars/female/female_2.png',
      bgColor: Color(0xFFFFF3E0),
    ),
    _AvatarOption(
      id: 'f_3',
      assetPath: 'assets/avatars/female/female_3.png',
      bgColor: Color(0xFFF3E5F5),
    ),
    _AvatarOption(
      id: 'f_4',
      assetPath: 'assets/avatars/female/female_4.png',
      bgColor: Color(0xFFE8F5E9),
    ),
    _AvatarOption(
      id: 'f_5',
      assetPath: 'assets/avatars/female/female_5.png',
      bgColor: Color(0xFFE0F7FA),
    ),
    _AvatarOption(
      id: 'f_6',
      assetPath: 'assets/avatars/female/female_6.png',
      bgColor: Color(0xFFFFF8E1),
    ),
  ];

  // ============================================================
  // MALE AVATARS
  // ============================================================

  final List<_AvatarOption> _maleAvatars = const [
    _AvatarOption(
      id: 'm_1',
      assetPath: 'assets/avatars/male/male_1.png',
      bgColor: Color(0xFFE3F2FD),
    ),
    _AvatarOption(
      id: 'm_2',
      assetPath: 'assets/avatars/male/male_2.png',
      bgColor: Color(0xFFFFF3E0),
    ),
    _AvatarOption(
      id: 'm_3',
      assetPath: 'assets/avatars/male/male_3.png',
      bgColor: Color(0xFFEDE7F6),
    ),
    _AvatarOption(
      id: 'm_4',
      assetPath: 'assets/avatars/male/male_4.png',
      bgColor: Color(0xFFE8F5E9),
    ),
    _AvatarOption(
      id: 'm_5',
      assetPath: 'assets/avatars/male/male_5.png',
      bgColor: Color(0xFFEFEBE9),
    ),
    _AvatarOption(
      id: 'm_6',
      assetPath: 'assets/avatars/male/male_6.png',
      bgColor: Color(0xFFECEFF1),
    ),
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    if (widget.gender != null) {
      _gender = widget.gender!.toLowerCase();
      _isLoadingGender = false;
    } else {
      _loadGenderFromFirestore();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // LOAD GENDER
  // ============================================================

  Future<void> _loadGenderFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
          _isLoadingGender = false;
        });

        return;
      }

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      final data = doc.data();

      setState(() {
        _gender = data?['gender']?.toString().toLowerCase();
        _isLoadingGender = false;
      });

      if (_gender != 'male' && _gender != 'female') {
        setState(() {
          _errorMessage = 'ما قدرناش نحددو الجنس تاع الحساب';
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'وقع خطأ فـ تحميل المعلومات';
        _isLoadingGender = false;
      });
    }
  }

  // ============================================================
  // AVATARS
  // ============================================================

  List<_AvatarOption> get _avatars {
    if (_gender == 'male') {
      return _maleAvatars;
    }

    return _femaleAvatars;
  }

  // ============================================================
  // SAVE AVATAR
  // ============================================================

  Future<void> _submit() async {
    if (_selectedIndex == null) {
      setState(() {
        _errorMessage = 'خاصك تختاري أفاتار باش تكملي';
      });

      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (!mounted) return;

        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
          _isSubmitting = false;
        });

        return;
      }

      final selected = _avatars[_selectedIndex!];

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'avatarId': selected.id,
          'avatarPath': selected.assetPath,
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;

      if (_gender == 'male') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const PreferencesScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const AboutYouScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'وقع خطأ، عاودي المحاولة';
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoadingGender
            ? const Center(
                child: CircularProgressIndicator(
                  color: darkGreen,
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ==================================================
                      // HEADER
                      // ==================================================
                      Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
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
                              child: const LinearProgressIndicator(
                                value: 0.75,
                                minHeight: 7,
                                backgroundColor: Color(0xFFE7E2D9),
                                valueColor: AlwaysStoppedAnimation<Color>(gold),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ==================================================
                      // ICON
                      // ==================================================
                      Center(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                darkGreen.withValues(alpha: 0.08),
                                gold.withValues(alpha: 0.14),
                              ],
                            ),
                            border: Border.all(
                              color: gold.withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: darkGreen.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: darkGreen,
                            size: 34,
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // TITLE
                      // ==================================================
                      const Text(
                        'اختاري الأفاتار متاعك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'هاذ الأفاتار غادي يبان فـ ملفك الشخصي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ==================================================
                      // CIRCULAR AVATARS — متقاربين من بعض، fit مضبوط
                      // ==================================================
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _avatars.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 6,
                          childAspectRatio: 0.85,
                        ),
                        itemBuilder: (context, index) {
                          final avatar = _avatars[index];
                          final bool selected = _selectedIndex == index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                                _errorMessage = null;
                              });
                            },
                            child: AnimatedScale(
                              scale: selected ? 1.06 : 1.0,
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutBack,
                              child: Center(
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  alignment: Alignment.center,
                                  children: [
                                    // ==================================================
                                    // AVATAR CIRCLE
                                    // ==================================================
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: avatar.bgColor,
                                        border: Border.all(
                                          color: selected ? gold : Colors.white,
                                          width: selected ? 4 : 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: selected
                                                ? gold.withValues(alpha: 0.40)
                                                : Colors.black.withValues(alpha: 0.08),
                                            blurRadius: selected ? 16 : 8,
                                            spreadRadius: selected ? 1.5 : 0,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      // ✅ الصورة تاخد بالضبط قياس الدائرة (بلا oversize)
                                      // بش ما يوقعش قص خاطئ حسب أبعاد كل صورة (مثال: avatar 6)
                                      child: ClipOval(
                                        child: SizedBox.expand(
                                          child: Image.asset(
                                            avatar.assetPath,
                                            fit: BoxFit.cover,
                                            alignment: Alignment.topCenter,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: avatar.bgColor,
                                                alignment: Alignment.center,
                                                child: const Icon(
                                                  Icons.person,
                                                  size: 40,
                                                  color: darkGreen,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    ),

                                    // ==================================================
                                    // CHECK
                                    // ==================================================
                                    if (selected)
                                      Positioned(
                                        right: -2,
                                        bottom: -2,
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: darkGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 15,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      // ==================================================
                      // ERROR
                      // ==================================================
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDE3B40).withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFDE3B40).withValues(alpha: 0.18),
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
                        ),
                      ],

                      const SizedBox(height: 26),

                      // ==================================================
                      // CONTINUE BUTTON
                      // ==================================================
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: _selectedIndex != null
                              ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [darkGreen, Color(0xFF1A6B4A)],
                                )
                              : LinearGradient(
                                  colors: [Colors.grey.shade300, Colors.grey.shade300],
                                ),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: _selectedIndex != null
                              ? [
                                  BoxShadow(
                                    color: darkGreen.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ]
                              : [],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _submit,
                            borderRadius: BorderRadius.circular(18),
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
                                          'متابعة',
                                          style: TextStyle(
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w700,
                                            color: _selectedIndex != null
                                                ? Colors.white
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 14,
                                          color: _selectedIndex != null
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

                      // ==================================================
                      // PRIVACY
                      // ==================================================
                      Row(
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
                              'تقدري تبدلي الأفاتار فـ أي وقت من إعدادات الملف الشخصي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// ============================================================
// AVATAR MODEL
// ============================================================

class _AvatarOption {
  final String id;
  final String assetPath;
  final Color bgColor;

  const _AvatarOption({
    required this.id,
    required this.assetPath,
    required this.bgColor,
  });
}