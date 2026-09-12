// screens/likes/likes_tab.dart
//
// ✅ صفحة "الإعجابات" — تعرض الدعوات (Invitations) الواصلة للمستخدم
// الحالي (status == pending فقط)، وتسمح له بـ:
//   - فتح Profile Preview (بدون فتح Chat)
//   - قبول الدعوة ✅ → ينشئ Match ثم يظهر فـ "المحادثات"
//   - رفض الدعوة ❌ → تختفي، بلا Match وبلا Chat
//
// 🎨 تصميم v3 — بطاقة "الصورة هي البطل" (photo-hero)، نفس لغة كارت
// الرئيسية بالضبط (صورة كبيرة + تدرّج + نص أبيض فوقها)، بدل بطاقة بيضاء
// صغيرة بأفاتار دائري. زوج أزرار دائرية عائمة (قبول/رفض) يركبان على
// حافة الصورة السفلية — نفس منطق تطبيقات المواعدة المعروفة، بألوان
// التطبيق (أخضر داكن/ذهبي) فقط، بلا أي تغيير فـ أي وظيفة أو استدعاء.

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
          color: darkGreen,
          child: Text(
            name.trim().isNotEmpty ? name.trim()[0] : '؟',
            style: const TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.w800,
              color: Colors.white24,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withOpacity(0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ================= الصورة (البطل الأساسي فـ الكارت) =================
          GestureDetector(
            onTap: onTapProfile,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              child: AspectRatio(
                aspectRatio: 1.05,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildPhoto(),
                    // تدرّج سفلي لقراءة النص
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 0.75, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.38),
                            Colors.black.withOpacity(0.78),
                          ],
                        ),
                      ),
                    ),
                    // شارة "جديد" أعلى اليمين
                    if (isFresh)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: gold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'جديد',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // وقت الإعجاب أعلى اليسار
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('❤️', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 4),
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // معلومات الشخص فوق الصورة مباشرة
                    Positioned(
                      bottom: 34,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isOnline)
                                Container(
                                  width: 9,
                                  height: 9,
                                  margin: const EdgeInsets.only(left: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade400,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.6),
                                  ),
                                ),
                              Flexible(
                                child: Text(
                                  age != null ? '$name، $age' : name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                    shadows: [
                                      Shadow(offset: Offset(0, 1), blurRadius: 6, color: Colors.black45),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (city != null && city!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, color: gold, size: 14),
                                const SizedBox(width: 3),
                                Text(
                                  city!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (bio != null && bio!.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              bio!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 12.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ============ أزرار قبول/رفض عائمة على حافة الصورة السفلية ============
          Transform.translate(
            offset: const Offset(0, -26),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _circleButton(
                    icon: Icons.close_rounded,
                    size: 52,
                    onTap: isBusy ? null : onReject,
                    background: Colors.white,
                    iconColor: rejectColor,
                    border: rejectColor.withOpacity(0.35),
                  ),
                  const SizedBox(width: 20),
                  _circleButton(
                    icon: Icons.favorite_rounded,
                    size: 64,
                    onTap: isBusy ? null : onAccept,
                    background: darkGreen,
                    iconColor: Colors.white,
                    glowColor: darkGreen,
                    isBusy: isBusy,
                  ),
                  const SizedBox(width: 20),
                  _circleButton(
                    icon: Icons.person_outline_rounded,
                    size: 52,
                    onTap: onTapProfile,
                    background: Colors.white,
                    iconColor: darkGreen,
                    border: darkGreen.withOpacity(0.15),
                  ),
                ],
              ),
            ),
          ),
          // نص "قبول لبدء المحادثة" أسفل الأزرار — يعوّض الفراغ اللي خلاه
          // الـTransform.translate بلا كسر أي تخطيط
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Center(
              child: Text(
                'اضغط ❤️ للقبول وبدء المحادثة',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required double size,
    required VoidCallback? onTap,
    Color? background,
    Gradient? gradient,
    required Color iconColor,
    Color? border,
    Color? glowColor,
    bool isBusy = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background,
          gradient: gradient,
          shape: BoxShape.circle,
          border: border != null ? Border.all(color: border, width: 1.4) : null,
          boxShadow: [
            BoxShadow(
              color: (glowColor ?? Colors.black).withOpacity(glowColor != null ? 0.25 : 0.10),
              blurRadius: glowColor != null ? 14 : 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: isBusy
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Icon(icon, color: iconColor, size: size * 0.42),
      ),
    );
  }
}