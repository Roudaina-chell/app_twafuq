// screens/profile/avatar_selection.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'about_you_screen.dart';
import 'preferences_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String? gender;

  const AvatarSelectionScreen({super.key, this.gender});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
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

  // أفاتارات مرسومة (DiceBear - Avataaars) بدل الإيموجي
  final List<_AvatarOption> _femaleAvatars = const [
    _AvatarOption(
      id: 'f_1',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Lina&top=longHairStraight&facialHairProbability=0&backgroundColor=fce4ec',
      bgColors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    ),
    _AvatarOption(
      id: 'f_2',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Amira&top=longHairCurly&facialHairProbability=0&backgroundColor=fff3e0',
      bgColors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    ),
    _AvatarOption(
      id: 'f_3',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Sarah&top=longHairBun&facialHairProbability=0&backgroundColor=f3e5f5',
      bgColors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    ),
    _AvatarOption(
      id: 'f_4',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Nour&top=hijab&facialHairProbability=0&backgroundColor=e0f7fa',
      bgColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    ),
    _AvatarOption(
      id: 'f_5',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Meriem&top=longHairFro&facialHairProbability=0&backgroundColor=e8f5e9',
      bgColors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
    ),
    _AvatarOption(
      id: 'f_6',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Rania&top=longHairMiaWallace&facialHairProbability=0&backgroundColor=fff8e1',
      bgColors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    ),
  ];

  final List<_AvatarOption> _maleAvatars = const [
    _AvatarOption(
      id: 'm_1',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Liam&top=shortHair&facialHairProbability=60&backgroundColor=b6e3f4',
      bgColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
    _AvatarOption(
      id: 'm_2',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Noah&top=shortHairShortFlat&facialHairProbability=80&backgroundColor=ffdfbf',
      bgColors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    ),
    _AvatarOption(
      id: 'm_3',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Adam&top=shortHairShortCurly&facialHairProbability=50&backgroundColor=d1d4f9',
      bgColors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    ),
    _AvatarOption(
      id: 'm_4',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Karim&top=shortHairShortWaved&facialHairProbability=70&backgroundColor=c0aede',
      bgColors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    ),
    _AvatarOption(
      id: 'm_5',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Yacine&top=shortHairDreads01&facialHairProbability=90&backgroundColor=ffd5dc',
      bgColors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
    ),
    _AvatarOption(
      id: 'm_6',
      imageUrl:
          'https://api.dicebear.com/9.x/avataaars/png?seed=Sami&top=shortHairSides&facialHairProbability=40&backgroundColor=e0f7fa',
      bgColors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    if (widget.gender != null) {
      _gender = widget.gender;
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

  Future<void> _loadGenderFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
          _isLoadingGender = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      setState(() {
        _gender = doc.data()?['gender'] as String?;
        _isLoadingGender = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'وقع خطأ فـ تحميل المعلومات';
        _isLoadingGender = false;
      });
    }
  }

  List<_AvatarOption> get _avatars =>
      _gender == 'male' ? _maleAvatars : _femaleAvatars;

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
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
        });
        return;
      }

      final selected = _avatars[_selectedIndex!];

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'avatarId': selected.id,
        'avatarUrl': selected.imageUrl,
      }, SetOptions(merge: true));

      if (mounted) {
        if (_gender == 'male') {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PreferencesScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AboutYouScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoadingGender
            ? const Center(child: CircularProgressIndicator(color: darkGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header مع شريط التقدم
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
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
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 0.75,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  gold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // أيقونة كبيرة في المنتصف
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                darkGreen.withValues(alpha: 0.08),
                                gold.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: gold.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.emoji_emotions_outlined,
                            color: darkGreen,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'اختاري الأفاتار متاعك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'هاذ الأفاتار غادي يبان فـ ملفك الشخصي',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 28),

                      // شبكة الأفاتارات
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _avatars.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 20,
                              crossAxisSpacing: 20,
                              childAspectRatio: 1,
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
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.elasticOut,
                              transform: selected
                                  ? (Matrix4.identity()..scale(1.08))
                                  : Matrix4.identity(),
                              transformAlignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: avatar.bgColors,
                                ),
                                border: Border.all(
                                  color: selected ? gold : Colors.white,
                                  width: selected ? 3 : 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: selected
                                        ? gold.withValues(alpha: 0.5)
                                        : Colors.black.withValues(alpha: 0.06),
                                    blurRadius: selected ? 16 : 6,
                                    spreadRadius: selected ? 2 : 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: ClipOval(
                                      child: Image.network(
                                        avatar.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        loadingBuilder:
                                            (context, child, progress) {
                                              if (progress == null)
                                                return child;
                                              return const Center(
                                                child: SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: darkGreen,
                                                      ),
                                                ),
                                              );
                                            },
                                        errorBuilder: (context, error, stack) =>
                                            const Icon(
                                              Icons.person,
                                              size: 36,
                                              color: darkGreen,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: darkGreen,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 28),

                      // زر متدرج
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: _selectedIndex != null
                              ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [darkGreen, Color(0xFF1A6B4A)],
                                )
                              : const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Colors.grey, Colors.grey],
                                ),
                          borderRadius: BorderRadius.circular(16),
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
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'متابعة',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 14,
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
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _AvatarOption {
  final String id;
  final String imageUrl;
  final List<Color> bgColors;

  const _AvatarOption({
    required this.id,
    required this.imageUrl,
    required this.bgColors,
  });
}
