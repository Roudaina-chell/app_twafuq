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

class _ProfilePreviewScreenState extends State<ProfilePreviewScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // معلومات الملف اللي كتجمعت طول الـ onboarding
  String _name = '';
  int? _age;
  String _job = '';
  String _city = '';
  String _educationLevel = '';
  int? _ageMin;
  int? _ageMax;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
        _name = (data['name'] as String?) ?? '';
        _age = data['age'] as int?;
        _job = (data['job'] as String?) ?? '';
        _city = (data['city'] as String?) ?? '';
        _educationLevel = (data['educationLevel'] as String?) ?? '';
        _ageMin = preferences['ageMin'] as int?;
        _ageMax = preferences['ageMax'] as int?;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: _isLoading
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
                      'المعاينة النهائية',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- بطاقة المعاينة ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // --- رأس البطاقة: صورة + اسم + عمر + مهنة/مدينة ---
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF3EFE8),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: darkGreen.withValues(alpha: 0.1),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: darkGreen,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _age != null ? '$_name. $_age' : _name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$_job - $_city',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // --- تفاصيل إضافية ---
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                _InfoRow(
                                  label: 'المستوى التعليمي',
                                  value: _educationLevel,
                                ),
                                const SizedBox(height: 10),
                                _InfoRow(label: 'المدينة', value: _city),
                                const SizedBox(height: 10),
                                _InfoRow(
                                  label: 'العمر',
                                  value: (_ageMin != null && _ageMax != null)
                                      ? '$_ageMax - $_ageMin'
                                      : '${_age ?? ''}',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _confirmProfile,
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
                                'تأكيد الملف',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// سطر معلومة: الليبل على اليمين، القيمة على اليسار (نفس التنسيق فالصورة)
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
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
      ],
    );
  }
}
