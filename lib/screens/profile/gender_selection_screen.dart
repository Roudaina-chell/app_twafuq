// screens/profile/gender_selection_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'formulaire_info.dart';

class GenderSelectionScreen extends StatefulWidget {
  const GenderSelectionScreen({super.key});

  @override
  State<GenderSelectionScreen> createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  String? _selectedGender;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _confirmSelection() async {
    if (_selectedGender == null) {
      setState(() {
        _errorMessage = 'خاصك تختاري الجنس باش تكملي';
      });
      return;
    }

    setState(() {
      _isLoading = true;
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

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'gender': _selectedGender,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FormulaireInfo()),
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
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // بطاقة اختيار الجنس (تصميم عمودي، صورة بدل الإيموجي/الأيقونة)
  // ============================================================
  Widget _genderCard({
    required String value,
    required String avatarAsset,
    required String label,
    required String description,
  }) {
    final bool selected = _selectedGender == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
          _errorMessage = null;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: selected ? darkGreen.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? darkGreen : Colors.grey.shade300,
            width: selected ? 2 : 1.2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // ============ الصورة الدائرية ============
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? darkGreen.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                border: Border.all(
                  color: selected ? gold : Colors.grey.shade300,
                  width: selected ? 2 : 1,
                ),
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Image.asset(
                    avatarAsset,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stack) {
                      debugPrint('❌ $avatarAsset load failed: $error');
                      return Icon(
                        value == 'male'
                            ? Icons.face_6_rounded
                            : Icons.face_3_rounded,
                        size: 34,
                        color: selected ? darkGreen : Colors.grey.shade500,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // ============ النص ============
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: selected ? darkGreen : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: selected
                          ? darkGreen.withValues(alpha: 0.7)
                          : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),

            // ============ علامة الاختيار ============
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? gold : Colors.transparent,
                border: Border.all(
                  color: selected ? gold : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ============================================================
                  // أيقونة كبيرة في الأعلى
                  // ============================================================
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: darkGreen.withValues(alpha: 0.08),
                      border: Border.all(
                        color: gold.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: darkGreen,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================================
                  // العنوان والوصف
                  // ============================================================
                  const Text(
                    'اختر نوع حسابك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اختر نوع الحساب المناسب لك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ============================================================
                  // بطاقتا الاختيار (تصميم عمودي)
                  // ============================================================
                  _genderCard(
                    value: 'female',
                    avatarAsset: 'assets/images/gender_female.png',
                    label: 'أنا امرأة',
                    description: 'حساب مخصص للنساء',
                  ),
                  _genderCard(
                    value: 'male',
                    avatarAsset: 'assets/images/gender_male.png',
                    label: 'أنا رجل',
                    description: 'حساب مخصص للرجال',
                  ),

                  // ============================================================
                  // عرض الخطأ إن وجد
                  // ============================================================
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ============================================================
                  // زر متابعة مع شريط تقدم
                  // ============================================================
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _confirmSelection,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedGender != null
                                ? darkGreen
                                : Colors.grey.shade400,
                            elevation: _selectedGender != null ? 4 : 0,
                            shadowColor: _selectedGender != null
                                ? darkGreen.withValues(alpha: 0.3)
                                : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'متابعة',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // شريط تقدم بسيط (مراحل الإعداد)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final bool active = index == 0;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: active ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active ? gold : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الخطوة 1 من 5',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
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
      ),
    );
  }
}
