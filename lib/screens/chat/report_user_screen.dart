// screens/chat/report_user_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ------------------------------------------------------------
// لوحة الألوان: تتبدل تلقائياً حسب المظهر (نهاري / ليلي)
// ------------------------------------------------------------
const Color _kDarkGreen = Color(0xFF0F3D2E);
const Color _kMidGreen = Color(0xFF1A6B4A);
const Color _kGold = Color(0xFFC9A24B);
const Color _kCream = Color(0xFFE6D5A8);

class _P {
  final bool isDark;
  final Color bg;
  final Color card;
  final Color title;
  final Color text;
  final Color subtitle;
  final Color icon;
  final Color iconBg;
  final Color border;
  final Color selectedBorder;
  final Color selectedFill;
  final Color unselectedIcon;
  final Color shadow;
  final Color error;
  final Color primaryBtn;

  const _P({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.title,
    required this.text,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.border,
    required this.selectedBorder,
    required this.selectedFill,
    required this.unselectedIcon,
    required this.shadow,
    required this.error,
    required this.primaryBtn,
  });

  static const _P light = _P(
    isDark: false,
    bg: Color(0xFFFAF7F2),
    card: Colors.white,
    title: _kDarkGreen,
    text: _kDarkGreen,
    subtitle: Color(0xFF757575),
    icon: _kDarkGreen,
    iconBg: Color(0x140F3D2E),
    border: Color(0xFFEEEEEE),
    selectedBorder: _kDarkGreen,
    selectedFill: Color(0x0F0F3D2E),
    unselectedIcon: Color(0xFFE0E0E0),
    shadow: Color(0x0D0F3D2E),
    error: Color(0xFFD32F2F),
    primaryBtn: _kDarkGreen,
  );

  static const _P dark = _P(
    isDark: true,
    bg: Color(0xFF0E1512),
    card: Color(0xFF17221D),
    title: _kGold,
    text: _kCream,
    subtitle: Color(0xFF8FA198),
    icon: _kGold,
    iconBg: Color(0x1AC9A24B),
    border: Color(0xFF2A3A33),
    selectedBorder: _kGold,
    selectedFill: Color(0x1AC9A24B),
    unselectedIcon: Color(0xFF3A4A43),
    shadow: Color(0x66000000),
    error: Color(0xFFFF8A80),
    primaryBtn: _kMidGreen,
  );

  static _P of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

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
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;
  bool _isBlocked = false;

  _P get _p => _P.of(context);

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ============================================================
  // أسباب الإبلاغ
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
        if (!mounted) return;
        setState(() => _isBlocked = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إلغاء حظر المستخدم'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final p = _p;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: p.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'حظر المستخدم',
              style: TextStyle(color: p.title, fontWeight: FontWeight.bold),
            ),
            content: Text(
              'عند حظر هذا المستخدم، لن يتمكن من مراسلتك أو رؤية معلوماتك. متأكد؟',
              style: TextStyle(fontSize: 13, color: p.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('إلغاء', style: TextStyle(color: p.subtitle)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
        if (!mounted) return;
        setState(() => _isBlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حظر المستخدم بنجاح'),
            backgroundColor: Colors.red,
          ),
        );
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

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        backgroundColor: p.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: p.icon),
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
                    color: p.iconBg,
                  ),
                  child: Icon(Icons.shield_rounded, color: p.icon, size: 34),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'الإبلاغ عن ${widget.userName}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: p.title,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'أخبرنا عن المشكلة التي تواجهها مع هذا المستخدم. لن يتم إشعاره بالإبلاغ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: p.subtitle,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اختر سبب الإبلاغ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: p.title,
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
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'تفاصيل إضافية (اختياري)',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: p.title,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(18),
                  border: p.isDark ? Border.all(color: p.border) : null,
                  boxShadow: [
                    BoxShadow(
                      color: p.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _detailsController,
                  maxLines: 3,
                  textAlign: TextAlign.right,
                  cursorColor: p.icon,
                  style: TextStyle(color: p.text),
                  decoration: InputDecoration(
                    hintText: 'اكتب أي تفاصيل إضافية هنا...',
                    hintStyle: TextStyle(color: p.subtitle),
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.primaryBtn,
                    disabledBackgroundColor: p.primaryBtn.withValues(
                      alpha: 0.6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                  label: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
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
                    side: BorderSide(color: p.error.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم',
                    style: TextStyle(
                      color: p.error,
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
                style: TextStyle(color: p.subtitle, fontSize: 11),
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

// ============================================================
// كارطة سبب الإبلاغ
// ============================================================
class _ReasonTile extends StatelessWidget {
  final _ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? Color.alphaBlend(p.selectedFill, p.card) : p.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? p.selectedBorder
                    : (p.isDark ? p.border : Colors.transparent),
                width: 1.4,
              ),
              boxShadow: selected || p.isDark
                  ? []
                  : [
                      BoxShadow(
                        color: p.shadow,
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: p.iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(reason.icon, color: p.icon, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: p.title,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        reason.subtitle,
                        style: TextStyle(fontSize: 11.5, color: p.subtitle),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? p.icon : p.unselectedIcon,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
