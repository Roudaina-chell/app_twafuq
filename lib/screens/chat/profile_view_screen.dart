// screens/profile/profile_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  bool _isLoading = true;
  bool _isBlocked = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, dynamic>? _userData;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkIfBlocked();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'الملف غير موجود';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _userData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ أثناء التحميل';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkIfBlocked() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .collection('blocked')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        setState(() => _isBlocked = true);
      }
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
    }
  }

  Future<void> _toggleBlock() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      if (_isBlocked) {
        // 🔓 إلغاء الحظر
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_myUid)
            .collection('blocked')
            .doc(widget.userId)
            .delete();

        setState(() => _isBlocked = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إلغاء حظر المستخدم'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 🔒 حظر المستخدم
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_myUid)
            .collection('blocked')
            .doc(widget.userId)
            .set({
          'blockedUserId': widget.userId,
          'blockedAt': FieldValue.serverTimestamp(),
        });

        setState(() => _isBlocked = true);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم حظر المستخدم بنجاح'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // رجوع للشاشة السابقة
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Block toggle failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، عاود المحاولة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _reportUser() async {
    if (_isSubmitting) return;

    // عرض حوار لإدخال سبب البلاغ
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'الإبلاغ عن مستخدم',
          style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'يرجى ذكر سبب الإبلاغ عن هذا المستخدم:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'اكتب السبب هنا...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('يرجى كتابة سبب الإبلاغ'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              await _submitReport(reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إبلاغ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReport(String reason) async {
    setState(() => _isSubmitting = true);

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterUserId': _myUid,
        'reportedUserId': widget.userId,
        'reportedUserName': widget.userName,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال البلاغ بنجاح، شكراً لك'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Report failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('حدث خطأ، عاود المحاولة'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'الملف الشخصي',
          style: const TextStyle(
            color: darkGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: darkGreen),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildProfileContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: darkGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    if (_userData == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final data = _userData!;
    final String name = data['fullName'] as String? ?? data['name'] as String? ?? 'مستخدم';
    final int? age = data['age'] as int?;
    final String city = data['city'] as String? ?? '';
    final String occupation = data['occupation'] as String? ?? data['job'] as String? ?? '';
    final String education = data['educationLevel'] as String? ?? '';
    final String bio = data['bio'] as String? ?? data['about'] as String? ?? '';
    final String? avatarAsset = data['avatarAsset'] as String?;
    final bool isOnline = data['isOnline'] == true;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ============================================================
          // ✅ بطاقة المعلومات الأساسية
          // ============================================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // الأفاتار مع الحالة
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: gold, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: ClipOval(
                          child: Container(
                            color: darkGreen.withValues(alpha: 0.08),
                            child: (avatarAsset == null || avatarAsset.isEmpty)
                                ? Icon(Icons.person, size: 56, color: darkGreen)
                                : Image.asset(
                                    avatarAsset,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    errorBuilder: (context, error, stack) =>
                                        Icon(Icons.person, size: 56, color: darkGreen),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // الاسم والعمر
                Text(
                  age != null ? '$name، $age' : name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 6),

                // المدينة
                if (city.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on_rounded, color: gold, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        city,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),

                const Divider(height: 24),

                // المهنة
                if (occupation.isNotEmpty)
                  _InfoRow(icon: Icons.work_outline, label: 'المهنة', value: occupation),

                // المستوى التعليمي
                if (education.isNotEmpty)
                  _InfoRow(icon: Icons.school_outlined, label: 'المستوى التعليمي', value: education),

                // النبذة
                if (bio.isNotEmpty)
                  _InfoRow(
                    icon: Icons.info_outline,
                    label: 'نبذة',
                    value: bio,
                    isMultiline: true,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ============================================================
          // ✅ أزرار الإجراءات (بلاغ / حظر)
          // ============================================================
          Row(
            children: [
              // زر الحظر
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _toggleBlock,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBlocked ? Colors.green.shade600 : Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text(
                    _isBlocked ? 'تم الحظر' : 'حظر',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // زر البلاغ
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _reportUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Text(
                    'إبلاغ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ملاحظة صغيرة
          Center(
            child: Text(
              'يمكنك إلغاء الحظر في أي وقت من هنا',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ✅ عنصر لعرض صف من المعلومات
// ============================================================
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF0F3D2E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}