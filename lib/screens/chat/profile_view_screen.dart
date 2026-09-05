// screens/chat/profile_view_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'report_user_screen.dart';

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
  bool _isMuted = false;
  bool _isDisappearing = false;
  bool _isSubmitting = false;
  int _unreadNotifCount = 0;
  String? _errorMessage;

  Map<String, dynamic>? _userData;

  String get _myUid => FirebaseAuth.instance.currentUser?.uid ?? '';

  String get _chatId {
    final ids = [_myUid, widget.userId]..sort();
    return ids.join('_');
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _checkIfBlocked();
    _checkIfMuted();
    _loadChatSettings();
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
      if (mounted && doc.exists) {
        setState(() => _isBlocked = true);
      }
    } catch (e) {
      debugPrint('❌ Check blocked failed: $e');
    }
  }

  // ============================================================
  // 🔕 كتم الإشعارات لهاذ المحادثة (users/{me}/muted/{otherUid})
  // ============================================================
  Future<void> _checkIfMuted() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .collection('muted')
          .doc(widget.userId)
          .get();
      if (mounted && doc.exists) {
        setState(() => _isMuted = true);
      }
    } catch (e) {
      debugPrint('❌ Check muted failed: $e');
    }
  }

  Future<void> _toggleMute() async {
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(_myUid)
          .collection('muted')
          .doc(widget.userId);
      if (_isMuted) {
        await ref.delete();
      } else {
        await ref.set({'mutedAt': FieldValue.serverTimestamp()});
      }
      if (!mounted) return;
      setState(() => _isMuted = !_isMuted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMuted ? '🔕 تم كتم إشعارات هذه المحادثة' : '🔔 تم إلغاء الكتم',
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Toggle mute failed: $e');
    }
  }

  // ============================================================
  // ⏱️ إعدادات المحادثة (الرسائل ذاتية الاختفاء) — chatSettings/{chatId}
  // ============================================================
  Future<void> _loadChatSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chatSettings')
          .doc(_chatId)
          .get();
      if (mounted && doc.exists) {
        setState(() => _isDisappearing = doc.data()?['disappearing'] == true);
      }
    } catch (e) {
      debugPrint('❌ Load chat settings failed: $e');
    }
  }

  Future<void> _toggleDisappearing() async {
    try {
      await FirebaseFirestore.instance
          .collection('chatSettings')
          .doc(_chatId)
          .set({'disappearing': !_isDisappearing}, SetOptions(merge: true));
      if (!mounted) return;
      setState(() => _isDisappearing = !_isDisappearing);
    } catch (e) {
      debugPrint('❌ Toggle disappearing failed: $e');
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
        final confirm = await _confirmDialog(
          title: 'حظر المستخدم',
          message: 'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك. متأكد؟',
          confirmLabel: 'حظر',
          confirmColor: Colors.red,
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
          Navigator.pop(context);
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

  // ============================================================
  // 🗑️ حذف المحادثة كاملة (كل الرسائل بيناتي أنا وهو)
  // ============================================================
  Future<void> _deleteConversation() async {
    final confirm = await _confirmDialog(
      title: 'حذف المحادثة',
      message: 'غادي تتحذف كل الرسائل بيناتكم نهائياً. هاذ الشي ما يتراجعش.',
      confirmLabel: 'حذف',
      confirmColor: Colors.red,
    );
    if (confirm != true) return;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('messages')
          .where('chatId', isEqualTo: _chatId)
          .get();
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('🗑️ تم حذف المحادثة')));
        // ✅ نرجعو 2 pops: هاذي الصفحة (profile view) + المحادثة لي
        // تحذفات — كنرجعو لقائمة المحادثات، ماشي لأول صفحة فـ التطبيق
        Navigator.pop(context);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Delete conversation failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ فشل الحذف: $e')));
      }
    }
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(color: darkGreen, fontWeight: FontWeight.bold),
        ),
        content: Text(message, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              confirmLabel,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🔍 بحث بسيط فـ رسائل هاذ المحادثة (فلترة من جانب العميل)
  // ============================================================
  Future<void> _openSearch() async {
    final controller = TextEditingController();
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allDocs = [];
    try {
      final snap = await FirebaseFirestore.instance
          .collection('messages')
          .where('chatId', isEqualTo: _chatId)
          .orderBy('timestamp', descending: true)
          .get();
      allDocs = snap.docs;
    } catch (e) {
      debugPrint('❌ Search load failed: $e');
    }
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = controller.text.trim();
            final results = query.isEmpty
                ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
                : allDocs.where((d) {
                    final text = (d.data()['text'] as String?) ?? '';
                    return text.contains(query);
                  }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search_rounded, color: darkGreen),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            textAlign: TextAlign.right,
                            decoration: const InputDecoration(
                              hintText: 'ابحث في المحادثة...',
                              border: InputBorder.none,
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: query.isEmpty
                          ? const Center(
                              child: Text(
                                'اكتب باش تبدا البحث',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : results.isEmpty
                          ? const Center(
                              child: Text(
                                'ماكاين حتى نتيجة',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                final data = results[index].data();
                                final text = (data['text'] as String?) ?? '';
                                final ts = data['timestamp'] as Timestamp?;
                                return ListTile(
                                  leading: const Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: darkGreen,
                                  ),
                                  title: Text(
                                    text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: ts != null
                                      ? Text(
                                          '${ts.toDate().day}/${ts.toDate().month}/${ts.toDate().year}',
                                          style: const TextStyle(fontSize: 11),
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: darkGreen),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: darkGreen),
            onSelected: (value) {
              if (value == 'delete') _deleteConversation();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text('حذف المحادثة'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: darkGreen))
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

  Widget _buildAvatarImage(String? source, double size) {
    if (source == null || source.trim().isEmpty) {
      return Icon(Icons.person, size: size * 0.55, color: darkGreen);
    }
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    return isNetwork
        ? Image.network(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) =>
                Icon(Icons.person, size: size * 0.55, color: darkGreen),
          )
        : Image.asset(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) =>
                Icon(Icons.person, size: size * 0.55, color: darkGreen),
          );
  }

  Widget _buildProfileContent() {
    if (_userData == null) {
      return const Center(child: Text('لا توجد بيانات'));
    }

    final data = _userData!;
    final String name =
        data['fullName'] as String? ?? data['name'] as String? ?? 'مستخدم';
    final String city = data['city'] as String? ?? '';
    final String? avatarAsset =
        (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
    final bool isOnline = data['isOnline'] == true;
    final Timestamp? joinedAt = data['createdAt'] as Timestamp?;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ============================================================
          // ✅ الأفاتار + الاسم + الحالة (بحال الصورة المرجعية)
          // ============================================================
          Center(
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: darkGreen.withValues(alpha: 0.08),
                        border: Border.all(color: gold, width: 2.5),
                      ),
                      child: ClipOval(
                        child: _buildAvatarImage(avatarAsset, 96),
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 4),
                if (isOnline)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'متصل الآن',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 22),

          // ============================================================
          // ✅ صف الإجراءات السريعة: بحث / إشعارات
          // ============================================================
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.search_rounded,
                  label: 'بحث في المحادثة',
                  onTap: _openSearch,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickActionCard(
                  icon: _isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_none_rounded,
                  label: 'الإشعارات',
                  badgeCount: _unreadNotifCount,
                  onTap: _toggleMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ============================================================
          // ✅ معلومات
          // ============================================================
          const _SectionLabel('معلومات'),
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.calendar_today_rounded,
            title: 'انضم في',
            value: joinedAt != null
                ? _formatMonthYear(joinedAt.toDate())
                : 'غير محدد',
          ),
          const SizedBox(height: 10),
          if (city.isNotEmpty)
            _InfoCard(
              icon: Icons.location_on_rounded,
              title: 'الموقع',
              value: city,
            ),

          const SizedBox(height: 22),

          // ============================================================
          // ✅ إعدادات الخصوصية
          // ============================================================
          const _SectionLabel('إعدادات الخصوصية'),
          const SizedBox(height: 8),
          const _InfoCard(
            icon: Icons.lock_rounded,
            title: 'التشفير',
            value: 'الرسائل والمكالمات مشفرة تماماً',
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.timer_outlined,
            title: 'الرسائل ذاتية الاختفاء',
            value: _isDisappearing ? 'مفعّلة' : 'متوقفة',
            onTap: _toggleDisappearing,
          ),

          const SizedBox(height: 22),

          // ============================================================
          // ✅ الإبلاغ / الحظر
          // ============================================================
          _ActionRow(
            icon: Icons.flag_rounded,
            label: 'الإبلاغ عن المستخدم',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ReportUserScreen(userId: widget.userId, userName: name),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _ActionRow(
            icon: _isBlocked ? Icons.check_circle_rounded : Icons.block_rounded,
            label: _isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم',
            onTap: _isSubmitting ? null : _toggleBlock,
          ),

          const SizedBox(height: 16),
          Center(
            child: Text(
              'لن يتمكن هذا المستخدم من مراسلتك أو رؤية معلوماتك.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthYear(DateTime d) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }
}

// ============================================================
// عنصر عام: تسمية قسم
// ============================================================
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Color(0xFF0F3D2E),
      ),
    );
  }
}

// ============================================================
// بطاقة إجراء سريع (بحث / إشعارات / وسائط)
// ============================================================
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF0F3D2E);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: darkGreen, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// بطاقة معلومة (انضم في / الموقع / التشفير / الرسائل ذاتية الاختفاء)
// ============================================================
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF0F3D2E);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: darkGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_left_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// صف إجراء أحمر (إبلاغ / حظر)
// ============================================================
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.red.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: Colors.red.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: Colors.red.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
