// screens/settings/blocked_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    if (diff.inDays < 365)
      return 'تم الحظر منذ ${(diff.inDays / 30).floor()} شهر';
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
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'إلغاء الحظر',
          style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.bold),
        ),
        content: Text('متأكد بغيتي تلغي الحظر على "${user.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'إلغاء الحظر',
              style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم إلغاء الحظر عن ${user.name}'),
          backgroundColor: kDarkGreen,
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: _uid.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: kDarkGreen),
                )
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
                                text: 'قائمة المستخدمين المحضورين',
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
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 26),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: kDarkGreen,
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
                                  color: kDarkGreen.withValues(alpha: 0.25),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'لا يوجد مستخدم محظور',
                                  style: TextStyle(color: Colors.grey.shade500),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: kDarkGreen.withValues(alpha: 0.08),
            backgroundImage:
                (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person_rounded, color: kDarkGreen, size: 21)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: kDarkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  user.blockedAtLabel,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
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
                      color: kDarkGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'إلغاء الحظر',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: kDarkGreen,
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
        color: kDarkGreen,
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kDarkGreen.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: kDarkGreen,
            size: 20,
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  }
}
