// screens/settings/blocked_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// محتفظ بها للتوافق مع ملفات أخرى قد تستوردها
const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class _BlockedUserInfo {
  final String id; // doc id in blockedUsers subcollection
  final String blockedUid;
  final String name;
  final String? avatarUrl;
  final Timestamp? blockedAt;

  const _BlockedUserInfo({
    required this.id,
    required this.blockedUid,
    required this.name,
    required this.avatarUrl,
    required this.blockedAt,
  });

  String get blockedAtLabel {
    if (blockedAt == null) return '';
    final diff = DateTime.now().difference(blockedAt!.toDate());
    if (diff.inDays < 1) return 'تم الحظر اليوم';
    if (diff.inDays < 30) return 'تم الحظر منذ ${diff.inDays} يوم';
    if (diff.inDays < 365) {
      return 'تم الحظر منذ ${(diff.inDays / 30).floor()} شهر';
    }
    return 'تم الحظر منذ ${(diff.inDays / 365).floor()} سنة';
  }
}

class BlockedListScreen extends StatefulWidget {
  const BlockedListScreen({super.key});

  @override
  State<BlockedListScreen> createState() => _BlockedListScreenState();
}

class _BlockedListScreenState extends State<BlockedListScreen> {
  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirmUnblock(_BlockedUserInfo user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final p = _Pal.of(ctx);
        return AlertDialog(
          backgroundColor: p.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            'إلغاء الحظر',
            style: TextStyle(color: p.primary, fontWeight: FontWeight.bold),
          ),
          content: Text('متأكد بغيتي تلغي الحظر على "${user.name}"؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('إلغاء', style: TextStyle(color: p.subtitle)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                'إلغاء الحظر',
                style: TextStyle(color: p.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      await _unblockUser(user);
    }
  }

  Future<void> _unblockUser(_BlockedUserInfo user) async {
    if (_uid.isEmpty) return;
    HapticFeedback.selectionClick();
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('blockedUsers')
        .doc(user.id)
        .delete();

    if (mounted) {
      final p = _Pal.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تم إلغاء الحظر عن ${user.name}',
            style: TextStyle(color: p.onPrimary),
          ),
          backgroundColor: p.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: _uid.isEmpty
              ? Center(child: CircularProgressIndicator(color: p.primary))
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .collection('blockedUsers')
                      .orderBy('blockedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final blockedUsers = docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _BlockedUserInfo(
                        id: doc.id,
                        blockedUid: (data['blockedUid'] as String?) ?? doc.id,
                        name: (data['name'] as String?) ?? 'مستخدم غير معروف',
                        avatarUrl: data['avatarUrl'] as String?,
                        blockedAt: data['blockedAt'] as Timestamp?,
                      );
                    }).toList();

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 44),
                            const Expanded(
                              child: _GradientTitle(
                                text: 'قائمة المستخدمين المحظورين',
                              ),
                            ),
                            _CircleIconButton(
                              icon: Icons.arrow_back,
                              onTap: () => Navigator.maybePop(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'إدارة قائمة المستخدمين الذين قمت بحظرهم',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: p.subtitle),
                        ),
                        const SizedBox(height: 26),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: p.primary,
                              ),
                            ),
                          )
                        else if (blockedUsers.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 60),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.block_rounded,
                                  size: 48,
                                  color: p.primary.withValues(alpha: 0.25),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا يوجد مستخدم محظور',
                                  style: TextStyle(color: p.subtitle),
                                ),
                              ],
                            ),
                          )
                        else
                          for (final user in blockedUsers) ...[
                            _BlockedUserTile(
                              user: user,
                              onUnblock: () => _confirmUnblock(user),
                            ),
                            const SizedBox(height: 14),
                          ],
                      ],
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  final _BlockedUserInfo user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    final hasAvatar = user.avatarUrl != null && user.avatarUrl!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.border),
        boxShadow: p.shadow(alpha: 0.05),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: p.primary.withValues(alpha: 0.08),
            backgroundImage: hasAvatar ? NetworkImage(user.avatarUrl!) : null,
            child: hasAvatar
                ? null
                : Icon(Icons.person_rounded, color: p.primary, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: p.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.blockedAtLabel,
                  style: TextStyle(fontSize: 11.5, color: p.muted),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: onUnblock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: p.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'إلغاء الحظر',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: p.primary,
                      ),
                    ),
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

class _GradientTitle extends StatelessWidget {
  final String text;
  final double fontSize;
  const _GradientTitle({required this.text, this.fontSize = 19});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: _Pal.of(context).primary,
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Material(
      color: p.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: p.shadow(alpha: 0.08, blur: 10, dy: 3),
          ),
          child: Icon(
            icon,
            color: p.primary,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ألوان مشتقة من الـ Theme الحالي (نهاري / ليلي) — خاصة بهذا الملف
// ---------------------------------------------------------------------------
class _Pal {
  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color bg;
  final Color card;
  final Color border;
  final Color subtitle;
  final Color muted;

  const _Pal._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.bg,
    required this.card,
    required this.border,
    required this.subtitle,
    required this.muted,
  });

  factory _Pal.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _Pal._(
      isDark: isDark,
      primary: theme.colorScheme.primary,
      onPrimary: theme.colorScheme.onPrimary,
      bg: theme.scaffoldBackgroundColor,
      card: theme.colorScheme.surface,
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.03),
      subtitle: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
      muted: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
    );
  }

  /// ظلال (تُلغى في الوضع الليلي)
  List<BoxShadow>? shadow({
    double alpha = 0.06,
    double blur = 18,
    double dy = 8,
  }) {
    if (isDark) return null;
    return [
      BoxShadow(
        color: primary.withValues(alpha: alpha),
        blurRadius: blur,
        offset: Offset(0, dy),
      ),
    ];
  }
}
