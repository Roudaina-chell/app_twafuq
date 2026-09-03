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
    with SingleTickerProviderStateMixin {
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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _loadProfile();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
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
    } catch (e) {
      setState(() {
        _errorMessage = 'وقع خطأ فـ تحميل المعلومات';
        _isLoading = false;
      });
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
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
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

  // ============================================================
  // ✅ ويدجت الأفاتار الحقيقي (صورة) بدل الأيقونة الثابتة
  // ============================================================
  Widget _buildAvatar() {
    if (_avatarAsset == null || _avatarAsset!.isEmpty) {
      return const Icon(Icons.person, color: Colors.white, size: 34);
    }
    return ClipOval(
      child: Image.asset(
        _avatarAsset!,
        width: 64,
        height: 64,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        errorBuilder: (context, error, stack) {
          debugPrint('❌ Profile avatar load failed: $_avatarAsset -> $error');
          return const Icon(Icons.person, color: Colors.white, size: 34);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: darkGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: darkGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: 1.0,
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

                      const Text(
                        'معاينة ملفك',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'تأكد من معلوماتك قبل الحفظ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // بطاقة المعاينة
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // رأس البطاقة - بالصورة والاسم
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: const BoxDecoration(
                                color: darkGreen,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Icon(
                                      Icons.verified,
                                      color: gold,
                                      size: 20,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(
                                            alpha: 0.12,
                                          ),
                                          border: Border.all(
                                            color: gold.withValues(alpha: 0.6),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: _buildAvatar(),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _age != null
                                                  ? '$_name، $_age'
                                                  : _name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _job,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.85,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              _city,
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.7,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const _SectionLabel(
                                      icon: Icons.info_outline,
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

                            // التفضيلات
                            Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const _SectionLabel(
                                    icon: Icons.tune,
                                    label: 'التفضيلات',
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    label: 'العمر',
                                    value: (_ageMin != null && _ageMax != null)
                                        ? '$_ageMin - $_ageMax سنة'
                                        : '${_age ?? ''}',
                                  ),
                                  const SizedBox(height: 10),
                                  _InfoRow(label: 'الولاية', value: _prefCity),
                                  const SizedBox(height: 10),
                                  _InfoRow(
                                    label: 'المستوى التعليمي',
                                    value: _educationLevel,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 24),

                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [darkGreen, Color(0xFF1A6B4A)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: darkGreen.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isSubmitting ? null : _confirmProfile,
                            borderRadius: BorderRadius.circular(16),
                            child: Center(
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                  : const Text(
                                      'حفظ الملف',
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
                    ],
                  ),
                ),
              ),
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
        Icon(icon, size: 16, color: _ProfilePreviewScreenState.gold),
        const SizedBox(width: 6),
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
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ],
    );
  }
}
