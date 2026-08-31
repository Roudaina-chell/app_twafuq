// screens/profile/avatar_selection.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'about_you_screen.dart';
import 'preferences_screen.dart';

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

  // مجموعة أفاتارات إيموجي عصرية لكل جنس، بألوان متدرجة أنيقة
  final List<_AvatarOption> _femaleAvatars = const [
    _AvatarOption(
      id: 'f_1',
      emoji: '👩',
      colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
    ),
    _AvatarOption(
      id: 'f_2',
      emoji: '👱‍♀️',
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    ),
    _AvatarOption(
      id: 'f_3',
      emoji: '👩‍🦱',
      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
    ),
    _AvatarOption(
      id: 'f_4',
      emoji: '👩‍🦰',
      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    ),
    _AvatarOption(
      id: 'f_5',
      emoji: '🧕',
      colors: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
    ),
    _AvatarOption(
      id: 'f_6',
      emoji: '👩‍🦳',
      colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
    ),
  ];

  final List<_AvatarOption> _maleAvatars = const [
    _AvatarOption(
      id: 'm_1',
      emoji: '👨',
      colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
    ),
    _AvatarOption(
      id: 'm_2',
      emoji: '👱‍♂️',
      colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
    ),
    _AvatarOption(
      id: 'm_3',
      emoji: '👨‍🦱',
      colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
    ),
    _AvatarOption(
      id: 'm_4',
      emoji: '👨‍🦰',
      colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
    ),
    _AvatarOption(
      id: 'm_5',
      emoji: '🧔',
      colors: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
    ),
    _AvatarOption(
      id: 'm_6',
      emoji: '👨‍🦳',
      colors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
    ),
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
        if (_gender == 'male') {
          // الرجال: أفاتار -> تفضيلات -> نبذة عنك -> Home
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const PreferencesScreen()),
            (route) => false,
          );
        } else {
          // النساء: أفاتار -> نبذة عنك -> Home
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
                            mainAxisSpacing: 22,
                            crossAxisSpacing: 22,
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
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            transform: selected
                                ? (Matrix4.identity()..scale(1.06))
                                : Matrix4.identity(),
                            transformAlignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: avatar.colors,
                              ),
                              border: Border.all(
                                color: selected ? gold : Colors.white,
                                width: selected ? 3 : 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: selected
                                      ? gold.withValues(alpha: 0.45)
                                      : Colors.black.withValues(alpha: 0.08),
                                  blurRadius: selected ? 14 : 6,
                                  spreadRadius: selected ? 1 : 0,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  avatar.emoji,
                                  style: const TextStyle(fontSize: 38),
                                ),
                                if (selected)
                                  Positioned(
                                    bottom: 2,
                                    right: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: darkGreen,
                                        shape: BoxShape.circle,
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
  final String emoji;
  final List<Color> colors;

  const _AvatarOption({
    required this.id,
    required this.emoji,
    required this.colors,
  });
}
