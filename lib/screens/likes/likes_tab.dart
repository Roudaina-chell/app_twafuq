// screens/likes/likes_tab.dart
//
// ✅ صفحة "الإعجابات" — تعرض الدعوات (Invitations) الواصلة للمستخدم
// الحالي (status == pending فقط)، وتسمح له بـ:
//   - فتح Profile Preview (بدون فتح Chat)
//   - قبول الدعوة ✅ → ينشئ Match ثم يظهر فـ "المحادثات"
//   - رفض الدعوة ❌ → تختفي، بلا Match وبلا Chat
//
// 🎨 تصميم v4 — Grid بعمودين، كارت بحال Facebook (صورة مربعة فوق +
// اسم/تفاصيل + زر قبول مليان وزر رفض رمادي فاتح كاملين العرض فوق
// بعضياتهم)، بألوان التطبيق (أخضر داكن/ذهبي).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/likes_service.dart';
import '../chat/profile_view_screen.dart';

class LikesTab extends StatefulWidget {
  const LikesTab({super.key});

  @override
  State<LikesTab> createState() => _LikesTabState();
}

class _LikesTabState extends State<LikesTab> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color darkGreenLight = Color(0xFF1A6B4A);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);
  static const Color reject = Color(0xFFE0637A);

  final Map<String, Map<String, dynamic>?> _userCache = {};
  final Set<String> _busyIds = {}; // دعوات قيد المعالجة (قبول/رفض)

  Future<Map<String, dynamic>?> _getUserInfo(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      _userCache[uid] = data;
      return data;
    } catch (e) {
      debugPrint('❌ Likes tab: user info fetch failed for $uid -> $e');
      _userCache[uid] = null;
      return null;
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final date = ts.toDate();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return 'منذ ${diff.inMinutes} د';
    if (diff.inDays < 1) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    return '${date.day}/${date.month}';
  }

  bool _isFresh(Timestamp? ts) {
    if (ts == null) return false;
    return DateTime.now().difference(ts.toDate()).inHours < 1;
  }

  Future<void> _handleAccept(LikeInvitation invitation) async {
    if (_busyIds.contains(invitation.id)) return;
    setState(() => _busyIds.add(invitation.id));
    try {
      await LikesService.instance.acceptInvitation(invitation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم قبول الإعجاب ❤️ يمكنك الآن بدء المحادثة.'),
          backgroundColor: darkGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } on LikeActionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: reject,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      debugPrint('❌ Accept invitation failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تعذر قبول الدعوة، حاول مرة أخرى'),
          backgroundColor: reject,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyIds.remove(invitation.id));
    }
  }

  Future<void> _handleReject(LikeInvitation invitation) async {
    if (_busyIds.contains(invitation.id)) return;
    setState(() => _busyIds.add(invitation.id));
    try {
      await LikesService.instance.rejectInvitation(invitation.id);
    } on LikeActionException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: reject,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      debugPrint('❌ Reject invitation failed: $e');
    } finally {
      if (mounted) setState(() => _busyIds.remove(invitation.id));
    }
  }

  void _openProfilePreview(String uid, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileViewScreen(userId: uid, userName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: StreamBuilder<List<LikeInvitation>>(
          stream: LikesService.instance.receivedInvitationsStream(),
          builder: (context, snap) {
            final invitations = snap.data ?? const [];
            final isLoading = snap.connectionState == ConnectionState.waiting;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isLoading ? null : invitations.length),
                const SizedBox(height: 4),
                Expanded(
                  child: Builder(builder: (context) {
                    if (isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: darkGreen,
                          strokeWidth: 2.6,
                        ),
                      );
                    }
                    if (snap.hasError) {
                      return _buildInfoState(
                        icon: Icons.error_outline_rounded,
                        title: 'تعذر تحميل الإعجابات',
                        subtitle: 'تأكد من الاتصال وعاود المحاولة',
                      );
                    }
                    if (invitations.isEmpty) {
                      return _buildInfoState(
                        icon: Icons.favorite_border_rounded,
                        title: 'لا توجد إعجابات جديدة حالياً',
                        subtitle:
                            'استمر في اكتشاف الأشخاص من الصفحة الرئيسية.',
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                      itemCount: invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = invitations[index];
                        return FutureBuilder<Map<String, dynamic>?>(
                          future: _getUserInfo(invitation.fromUserId),
                          builder: (context, userSnap) {
                            final data = userSnap.data;
                            final name = (data?['fullName'] as String?) ??
                                (data?['name'] as String?) ??
                                'مستخدم';
                            final age = (data?['age'] as num?)?.toInt();
                            final city = data?['city'] as String?;
                            final bio = (data?['bio'] as String?) ??
                                (data?['about'] as String?);
                            final avatarAsset =
                                (data?['avatarAsset'] as String?) ??
                                    (data?['avatarPath'] as String?);
                            final isOnline = data?['isOnline'] == true;

                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 1),
                              duration: Duration(milliseconds: 260 + (index * 40).clamp(0, 300)),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, child) => Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 16),
                                  child: child,
                                ),
                              ),
                              child: _InvitationCard(
                                name: name,
                                age: age,
                                city: city,
                                bio: bio,
                                avatarAsset: avatarAsset,
                                isOnline: isOnline,
                                isFresh: _isFresh(invitation.createdAt),
                                timeLabel: _formatTimestamp(invitation.createdAt),
                                isBusy: _busyIds.contains(invitation.id),
                                darkGreen: darkGreen,
                                darkGreenLight: darkGreenLight,
                                gold: gold,
                                rejectColor: reject,
                                onTapProfile: () => _openProfilePreview(
                                    invitation.fromUserId, name),
                                onAccept: () => _handleAccept(invitation),
                                onReject: () => _handleReject(invitation),
                              ),
                            );
                          },
                        );
                      },
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(int? count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'الإعجابات',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: darkGreen,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'أشخاص أعجبوا بك ويريدون التعرف عليك',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (count != null && count > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: darkGreen,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withOpacity(0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'جديد',
                    style: TextStyle(
                      color: gold.withOpacity(0.95),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 104,
              height: 104,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: gold.withOpacity(0.25), width: 1.4),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: darkGreen.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 38, color: darkGreen),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: darkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// 🧩 بطاقة دعوة واحدة — Photo-hero (نفس لغة كارت الرئيسية)
// ============================================================
class _InvitationCard extends StatelessWidget {
  final String name;
  final int? age;
  final String? city;
  final String? bio;
  final String? avatarAsset;
  final bool isOnline;
  final bool isFresh;
  final String timeLabel;
  final bool isBusy;
  final Color darkGreen;
  final Color darkGreenLight;
  final Color gold;
  final Color rejectColor;
  final VoidCallback onTapProfile;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InvitationCard({
    required this.name,
    required this.age,
    required this.city,
    required this.bio,
    required this.avatarAsset,
    required this.isOnline,
    required this.isFresh,
    required this.timeLabel,
    required this.isBusy,
    required this.darkGreen,
    required this.darkGreenLight,
    required this.gold,
    required this.rejectColor,
    required this.onTapProfile,
    required this.onAccept,
    required this.onReject,
  });

  Widget _buildPhoto() {
    Widget fallback() => Container(
          alignment: Alignment.center,
          color: darkGreen.withOpacity(0.10),
          child: Text(
            name.trim().isNotEmpty ? name.trim()[0] : '؟',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: darkGreen.withOpacity(0.35),
            ),
          ),
        );

    if (avatarAsset == null || avatarAsset!.trim().isEmpty) {
      return fallback();
    }
    final isNetwork =
        avatarAsset!.startsWith('http://') || avatarAsset!.startsWith('https://');
    return isNetwork
        ? Image.network(
            avatarAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => fallback(),
          )
        : Image.asset(
            avatarAsset!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => fallback(),
          );
  }

  @override
  Widget build(BuildContext context) {
    // ============================================================
    // 🟦 صف "دعوة" بحال Facebook (Friend Requests) بالضبط: صف واحد
    // بحجم ثابت — صورة صغيرة + اسم/تفاصيل — وتحته زوج أزرار كاملي
    // العرض (قبول أخضر مليان، رفض رمادي فاتح). كل الصفوف بنفس الحجم
    // بالضبط (بلا اختلاف فـ الطول حسب طول النص).
    // ============================================================
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: onTapProfile,
            behavior: HitTestBehavior.opaque,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ================= التفاصيل النصية (يمين) =================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        age != null ? '$name، $age' : name,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                        ),
                      ),
                      if (city != null && city!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          city!,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        isFresh ? 'أعجب بك الآن' : 'أعجب بك $timeLabel',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ================= الصورة (يسار، حجم ثابت) =================
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: _buildPhoto(),
                      ),
                    ),
                    if (isFresh)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (isOnline)
                      Positioned(
                        bottom: 3,
                        left: 3,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green.shade500,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // ============ زوج الأزرار (قبول / رفض) جنب بعضياتهم ============
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'رفض',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isBusy ? null : onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'قبول',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}