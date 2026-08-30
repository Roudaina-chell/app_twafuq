// screens/profile/avatar_selection.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class AvatarSelectionScreen extends StatefulWidget {
  // Optional: نقدر نمررو الجنس مباشرة من formulaire_info/gender_selection
  // باش ما نديرش قراية زايدة من Firestore. إذا ماجاش، نجيبوه حنا.
  final String? gender;

  const AvatarSelectionScreen({super.key, this.gender});

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  String? _gender;
  bool _isLoadingGender = true;
  int? _selectedIndex;
  bool _isSubmitting = false;
  String? _errorMessage;

  // مجموعة أفاتارات جاهزة (أيقونة + لون خلفية) لكل جنس
  final List<_AvatarOption> _femaleAvatars = const [
    _AvatarOption(id: 'f_1', icon: Icons.face_3, color: Color(0xFFEBC9D2)),
    _AvatarOption(id: 'f_2', icon: Icons.face_4, color: Color(0xFFE3D2C3)),
    _AvatarOption(id: 'f_3', icon: Icons.face_6, color: Color(0xFFD9C9E8)),
    _AvatarOption(id: 'f_4', icon: Icons.face_2, color: Color(0xFFC9E1D2)),
    _AvatarOption(id: 'f_5', icon: Icons.face, color: Color(0xFFF0D9B5)),
    _AvatarOption(id: 'f_6', icon: Icons.face_3, color: Color(0xFFC9D8E8)),
  ];

  final List<_AvatarOption> _maleAvatars = const [
    _AvatarOption(id: 'm_1', icon: Icons.face, color: Color(0xFFC9D8E8)),
    _AvatarOption(id: 'm_2', icon: Icons.face_6, color: Color(0xFFD2C9E8)),
    _AvatarOption(id: 'm_3', icon: Icons.face_4, color: Color(0xFFC9E8DC)),
    _AvatarOption(id: 'm_4', icon: Icons.face_2, color: Color(0xFFE8D9C9)),
    _AvatarOption(id: 'm_5', icon: Icons.face_3, color: Color(0xFFE8C9C9)),
    _AvatarOption(id: 'm_6', icon: Icons.face, color: Color(0xFFC9E8E3)),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.gender != null) {
      _gender = widget.gender;
      _isLoadingGender = false;
    } else {
      _loadGenderFromFirestore();
    }
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
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
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
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: _isLoadingGender
            ? const Center(child: CircularProgressIndicator(color: darkGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back, color: darkGreen),
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
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: darkGreen.withValues(alpha: 0.08),
                        ),
                        child: const Icon(
                          Icons.emoji_emotions_outlined,
                          color: darkGreen,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'اختاري الأفاتار متاعك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
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
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _avatars.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 18,
                            crossAxisSpacing: 18,
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
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: avatar.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? gold : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: gold.withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Icon(
                              avatar.icon,
                              size: 36,
                              color: darkGreen,
                            ),
                          ),
                        );
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'متابعة',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
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
                            style: TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AvatarOption {
  final String id;
  final IconData icon;
  final Color color;

  const _AvatarOption({
    required this.id,
    required this.icon,
    required this.color,
  });
}
