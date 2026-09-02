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
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,

                    children: [

                      // ==================================================
                      // HEADER
                      // ==================================================

                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.maybePop(context);
                            },

                            icon: const Icon(
                              Icons.arrow_back,
                              color: darkGreen,
                            ),
                          ),

                          const Text(
                            'TAWAFUQ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: darkGreen,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(width: 12),

                          Expanded(
                            child: ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(4),

                              child:
                                  const LinearProgressIndicator(
                                value: 0.75,
                                minHeight: 6,

                                backgroundColor:
                                    Color(0xFFE0E0E0),

                                valueColor:
                                    AlwaysStoppedAnimation<
                                        Color>(
                                  gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ==================================================
                      // ICON
                      // ==================================================

                      Center(
                        child: Container(
                          width: 80,
                          height: 80,

                          decoration:
                              BoxDecoration(
                            shape: BoxShape.circle,

                            gradient:
                                LinearGradient(
                              begin:
                                  Alignment.topLeft,
                              end:
                                  Alignment.bottomRight,

                              colors: [
                                darkGreen.withValues(
                                  alpha: 0.08,
                                ),
                                gold.withValues(
                                  alpha: 0.12,
                                ),
                              ],
                            ),

                            border: Border.all(
                              color:
                                  gold.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),

                          child: const Icon(
                            Icons
                                .emoji_emotions_outlined,
                            color: darkGreen,
                            size: 36,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // TITLE
                      // ==================================================

                      const Text(
                        'اختاري الأفاتار متاعك',

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'هاذ الأفاتار غادي يبان فـ ملفك الشخصي',

                        textAlign:
                            TextAlign.center,

                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ==================================================
                      // CIRCULAR AVATARS
                      // NO SQUARE CARDS
                      // ==================================================

                      GridView.builder(
                        shrinkWrap: true,

                        physics:
                            const NeverScrollableScrollPhysics(),

                        itemCount: _avatars.length,

                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,

                          mainAxisSpacing: 22,

                          crossAxisSpacing: 22,

                          childAspectRatio: 1,
                        ),

                        itemBuilder:
                            (context, index) {
                          final avatar =
                              _avatars[index];

                          final bool selected =
                              _selectedIndex ==
                                  index;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIndex =
                                    index;

                                _errorMessage =
                                    null;
                              });
                            },

                            child:
                                AnimatedScale(
                              scale: selected
                                  ? 1.05
                                  : 1.0,

                              duration:
                                  const Duration(
                                milliseconds: 250,
                              ),

                              curve:
                                  Curves.easeOutBack,

                              child: Center(
                                child: Stack(
                                  alignment:
                                      Alignment.center,

                                  children: [

                                    // ==================================================
                                    // AVATAR CIRCLE
                                    // ==================================================

                                    AnimatedContainer(
                                      duration:
                                          const Duration(
                                        milliseconds: 250,
                                      ),

                                      width: 155,
                                      height: 155,

                                      decoration:
                                          BoxDecoration(
                                        shape:
                                            BoxShape.circle,

                                        color:
                                            avatar.bgColor,

                                        border:
                                            Border.all(
                                          color: selected
                                              ? gold
                                              : Colors.white,

                                          width: selected
                                              ? 5
                                              : 4,
                                        ),

                                        boxShadow: [
                                          BoxShadow(
                                            color: selected
                                                ? gold.withValues(
                                                    alpha: 0.40,
                                                  )
                                                : Colors.black
                                                    .withValues(
                                                    alpha: 0.10,
                                                  ),

                                            blurRadius:
                                                selected
                                                    ? 18
                                                    : 10,

                                            spreadRadius:
                                                selected
                                                    ? 2
                                                    : 0,

                                            offset:
                                                const Offset(
                                              0,
                                              5,
                                            ),
                                          ),
                                        ],
                                      ),

                                      child:
                                          ClipOval(
                                        child:
                                            Image.asset(
                                          avatar.assetPath,

                                          width: 155,
                                          height: 155,

                                          // الصورة تتقص داخل الدائرة
                                          fit: BoxFit.cover,

                                          errorBuilder:
                                              (
                                            context,
                                            error,
                                            stackTrace,
                                          ) {
                                            return const Center(
                                              child:
                                                  Icon(
                                                Icons.person,
                                                size: 55,
                                                color:
                                                    darkGreen,
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),

                                    // ==================================================
                                    // CHECK
                                    // ==================================================

                                    if (selected)
                                      Positioned(
                                        right: 2,
                                        bottom: 2,

                                        child:
                                            Container(
                                          width: 32,
                                          height: 32,

                                          decoration:
                                              BoxDecoration(
                                            color:
                                                darkGreen,

                                            shape:
                                                BoxShape
                                                    .circle,

                                            border:
                                                Border.all(
                                              color:
                                                  Colors.white,
                                              width: 2,
                                            ),
                                          ),

                                          child:
                                              const Icon(
                                            Icons.check,
                                            size: 18,
                                            color:
                                                Colors.white,
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
                        const SizedBox(height: 16),

                        Text(
                          _errorMessage!,

                          textAlign:
                              TextAlign.center,

                          style:
                              const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      // ==================================================
                      // CONTINUE BUTTON
                      // ==================================================

                      AnimatedContainer(
                        duration:
                            const Duration(
                          milliseconds: 300,
                        ),

                        height: 54,

                        decoration:
                            BoxDecoration(
                          gradient:
                              _selectedIndex != null
                                  ? const LinearGradient(
                                      begin:
                                          Alignment
                                              .centerLeft,
                                      end:
                                          Alignment
                                              .centerRight,

                                      colors: [
                                        darkGreen,
                                        Color(
                                          0xFF1A6B4A,
                                        ),
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Colors.grey,
                                        Colors.grey,
                                      ],
                                    ),

                          borderRadius:
                              BorderRadius.circular(
                            16,
                          ),

                          boxShadow:
                              _selectedIndex != null
                                  ? [
                                      BoxShadow(
                                        color:
                                            darkGreen
                                                .withValues(
                                          alpha: 0.35,
                                        ),

                                        blurRadius: 20,

                                        offset:
                                            const Offset(
                                          0,
                                          8,
                                        ),
                                      ),
                                    ]
                                  : [],
                        ),

                        child: Material(
                          color:
                              Colors.transparent,

                          child: InkWell(
                            onTap: _isSubmitting
                                ? null
                                : _submit,

                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),

                            child: Center(
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color:
                                          Colors.white,
                                    )
                                  : const Text(
                                      'متابعة',

                                      style:
                                          TextStyle(
                                        fontSize: 17,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                        color: Colors
                                            .white,
                                      ),
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
                        mainAxisAlignment:
                            MainAxisAlignment.center,

                        children: [
                          const Icon(
                            Icons
                                .shield_outlined,
                            size: 14,
                            color: darkGreen,
                          ),

                          const SizedBox(width: 6),

                          const Expanded(
                            child: Text(
                              'تقدري تبدلي الأفاتار فـ أي وقت من إعدادات الملف الشخصي',

                              textAlign:
                                  TextAlign.center,

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