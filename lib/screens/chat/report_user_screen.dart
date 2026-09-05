// screens/chat/report_user_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReportUserScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const ReportUserScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<ReportUserScreen> createState() => _ReportUserScreenState();
}

class _ReportUserScreenState extends State<ReportUserScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  bool _isBlocked = false;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ============================================================
  // ✅ أسباب الإبلاغ (بحال الصورة المرجعية)
  // ============================================================
  static const List<_ReportReason> _reasons = [
    _ReportReason(
      id: 'harassment',
      icon: Icons.pan_tool_alt_outlined,
      title: 'إزعاج أو مضايقة',
      subtitle: 'رسائل مزعجة أو غير مرغوب فيها',
    ),
    _ReportReason(
      id: 'inappropriate',
      icon: Icons.image_not_supported_outlined,
      title: 'محتوى غير لائق',
      subtitle: 'صور أو رسائل تحتوي على محتوى غير لائق',
    ),
    _ReportReason(
      id: 'scam',
      icon: Icons.shield_outlined,
      title: 'احتيال أو نصب',
      subtitle: 'محاولة احتيال أو طلب معلومات شخصية',
    ),
    _ReportReason(
      id: 'false_info',
      icon: Icons.description_outlined,
      title: 'معلومات خاطئة',
      subtitle: 'معلومات كاذبة أو مضللة',
    ),
    _ReportReason(
      id: 'other',
      icon: Icons.spa_outlined,
      title: 'أخرى',
      subtitle: 'سبب آخر',
    ),
  ];

  String _selectedReasonId = _reasons.first.id;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _checkIfBlocked() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .collection('blocked')
          .doc(widget.userId)
          .get();
      if (mounted && doc.exists) {
        setState(() => _isBlocked = true);
      }
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
    }
  }

  Future<void> _submitReport() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final reason = _reasons.firstWhere((r) => r.id == _selectedReasonId);
    final details = _detailsController.text.trim();

    try {
      await FirebaseFirestore.instance.collection('reports').add({
        'reporterUserId': _myUid,
        'reportedUserId': widget.userId,
        'reportedUserName': widget.userName,
        'reasonId': reason.id,
        'reasonLabel': reason.title,
        'details': details,
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

  Future<void> _toggleBlock() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .collection('blocked')
          .doc(widget.userId);

      if (_isBlocked) {
        await ref.delete();
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
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'حظر المستخدم',
              style: TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'عند حظر هذا المستخدم، لن يتمكن من مراسلتك أو رؤية معلوماتك. متأكد؟',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('حظر', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        if (confirm != true) return;

        await ref.set({
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
          Navigator.pop(
            context,
          ); // ✅ pop وحدة برك — نرجعو لي دار push (المحادثة أو profile view)
        }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkGreen),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkGreen.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.shield_rounded,
                    color: darkGreen,
                    size: 34,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الإبلاغ عن ${widget.userName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أخبرنا عن المشكلة التي تواجهها مع هذا المستخدم. لن يتم إشعاره بالإبلاغ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر سبب الإبلاغ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ..._reasons.map(
                (reason) => _ReasonTile(
                  reason: reason,
                  selected: _selectedReasonId == reason.id,
                  onTap: () => setState(() => _selectedReasonId = reason.id),
                ),
              ),
              const SizedBox(height: 18),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تفاصيل إضافية (اختياري)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: darkGreen,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  decoration: const InputDecoration(
                    hintText: 'اكتب أي تفاصيل إضافية هنا...',
                    contentPadding: EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إرسال الإبلاغ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _toggleBlock,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'عند حظر هذا المستخدم، لن يتمكن من مراسلتك أو رؤية معلوماتك.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportReason {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;

  const _ReportReason({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _ReasonTile extends StatelessWidget {
  final _ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  static const Color darkGreen = Color(0xFF0F3D2E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? darkGreen : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(reason.icon, color: darkGreen, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: selected,
                  onChanged: (_) => onTap(),
                  activeColor: darkGreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
