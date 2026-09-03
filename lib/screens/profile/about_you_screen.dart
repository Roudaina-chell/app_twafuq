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
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);
  static const int _maxLength = 250;
  static const int _maxInterests = 6;

  final TextEditingController _bioController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  // ✅ قائمة الاهتمامات اللي يقدر المستخدم يختار منها (بزاف حوايج يحبهم)
  final List<String> _allInterests = const [
    'القراءة',
    'السفر',
    'الرياضة',
    'الطبخ',
    'الموسيقى',
    'السينما',
    'التصوير',
    'الفن',
    'التكنولوجيا',
    'المشي',
    'كرة القدم',
    'اليوغا',
    'القهوة',
    'الألعاب',
    'الكتابة',
    'الطبيعة',
  ];

  final Set<String> _selectedInterests = {};

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      setState(() {});
    });
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _bioController.dispose();
    _animationController.dispose();
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
        _errorMessage = 'خاصك تكتب نبذة عنك باش تكملي';
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
        _errorMessage = 'وقع خطأ، عاود المحاولة';
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
    final int currentLength = _bioController.text.characters.length;
    final bool canSubmit = _bioController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
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
                          child: LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 7,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(gold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // أيقونة كبيرة في المنتصف
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
                        border: Border.all(color: gold.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: darkGreen.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.edit_note_outlined,
                        color: darkGreen,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'نبذة عنك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'اكتب نبذة مختصرة عنك وختار الحوايج اللي تحبها',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ==================================================
                  // حقل النص
                  // ==================================================
                  Container(
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
                      children: [
                        TextField(
                          controller: _bioController,
                          maxLength: _maxLength,
                          maxLines: 5,
                          textAlign: TextAlign.right,
                          decoration: InputDecoration(
                            hintText: 'اكتب هنا...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: currentLength > 0 ? 1 : 0,
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: darkGreen, size: 14),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'تمام',
                                      style: TextStyle(
                                        color: darkGreen,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$currentLength/$_maxLength',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // الاهتمامات — هنا يقدر يحط بزاف حوايج يحبهم
                  // ==================================================
                  Container(
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
                              child: const Icon(Icons.favorite_border_rounded,
                                  color: darkGreen, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'شنو تحب؟',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: darkGreen,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
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
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ختار لحد $_maxInterests حوايج تعبر عليك',
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
                          children: _allInterests.map((interest) {
                            final bool selected =
                                _selectedInterests.contains(interest);
                            final bool disabled = !selected &&
                                _selectedInterests.length >= _maxInterests;

                            return GestureDetector(
                              onTap: disabled
                                  ? null
                                  : () => _toggleInterest(interest),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? darkGreen
                                      : (disabled
                                          ? Colors.grey.shade100
                                          : darkGreen.withValues(alpha: 0.05)),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: selected
                                        ? darkGreen
                                        : (disabled
                                            ? Colors.grey.shade200
                                            : gold.withValues(alpha: 0.35)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (selected) ...[
                                      const Icon(Icons.check_rounded,
                                          size: 14, color: Colors.white),
                                      const SizedBox(width: 5),
                                    ],
                                    Text(
                                      interest,
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
                          )
                        : const SizedBox(key: ValueKey('noerr'), height: 0),
                  ),

                  const SizedBox(height: 22),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: canSubmit
                          ? const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [darkGreen, Color(0xFF1A6B4A)],
                            )
                          : LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade300,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: canSubmit
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: darkGreen),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'تقدر تبدل النبذة والاهتمامات فـ أي وقت من إعدادات الملف الشخصي',
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
        ),
      ),
    );
  }
}