// screens/profile/profile_edit_screen.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'personal_info_edit_screen.dart';
import '../settings/appearance_screen.dart';
import '../settings/language_screen.dart';
import '../settings/security_privacy_screen.dart';
import '../../services/likes_service.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kDarkGreenLight = Color(0xFF1A6B4A);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  // ============================================================
  // 🗄️ CACHE بسيط على مستوى الـ class (static) — كيبقى محفوظ
  // طول ما التطبيق خدام، باش كي نرجعو لـ "حسابي" مرة أخرى، الاسم
  // والأفاتار يبانو دغيا (بلا فلاش أبيض / بلا سبينر) وقت لي
  // Firestore كيرفريشي البيانات فالخلفية.
  // ============================================================
  static String? _cachedName;
  static String? _cachedAvatarAsset;

  late String _name = _cachedName ?? '';
  late String? _avatarAsset = _cachedAvatarAsset;

  // ✅ ماكاينش "isLoading" كيخبي الصفحة كاملها دابا. هاد الفلاغ
  // كيتحكم غير فـ الهيدر (اسم/أفاتار) — الباقي (settings + bottom
  // nav) يبان مباشرة، حتى قبل ما توصل البيانات.
  bool _isHeaderLoading = true;

  int _pendingInvitationsCount = 0;
  int _unreadMessagesCount = 0;
  StreamSubscription<List<LikeInvitation>>? _invitationsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _unreadMsgsSub;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    // إلا كان عندنا cache من قبل، الهيدر يبان مباشرة بلا "تحميل".
    _isHeaderLoading = _cachedName == null;
    _loadAccount();
    _attachLiveBadges();
  }

  @override
  void dispose() {
    _invitationsSub?.cancel();
    _unreadMsgsSub?.cancel();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    try {
      if (_uid.isEmpty) {
        if (mounted) setState(() => _isHeaderLoading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final data = doc.data() ?? {};

      final name =
          (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
      final avatar =
          (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);

      // نحدّثو الـ cache باش المرة الجاية يبان مباشرة.
      _cachedName = name;
      _cachedAvatarAsset = avatar;

      if (!mounted) return;
      setState(() {
        _name = name;
        _avatarAsset = avatar;
        _isHeaderLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isHeaderLoading = false);
    }
  }

  void _attachLiveBadges() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _invitationsSub = LikesService.instance.receivedInvitationsStream().listen((
      list,
    ) {
      if (!mounted) return;
      setState(() => _pendingInvitationsCount = list.length);
    }, onError: (e) => debugPrint('❌ Invitations badge stream failed: $e'));

    _unreadMsgsSub = FirebaseFirestore.instance
        .collection('messages')
        .where('toUserId', isEqualTo: uid)
        .where('read', isEqualTo: false)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() => _unreadMessagesCount = snap.docs.length);
          },
          onError: (e) =>
              debugPrint('❌ Unread messages badge stream failed: $e'),
        );
  }

  Widget _buildAvatar({double size = 46}) {
    if (_avatarAsset == null || _avatarAsset!.trim().isEmpty) {
      return Icon(Icons.person, size: size, color: kDarkGreen);
    }
    final isNetwork =
        _avatarAsset!.startsWith('http://') ||
        _avatarAsset!.startsWith('https://');
    final fallback = Icon(Icons.person, size: size, color: kDarkGreen);
    final image = isNetwork
        ? Image.network(
            _avatarAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) => fallback,
          )
        : Image.asset(
            _avatarAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) => fallback,
          );
    return ClipOval(child: image);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('خطأ فـ تسجيل الخروج: $e')));
      }
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _openSecurityPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen()),
    );
  }

  // ============================================================
  // 🏗️ BUILD — دابا كترجع الصفحة كاملة (header + settings +
  // bottom nav) من أول فريم، بلا "if (_isLoading) return Scaffold
  // فارغ". الـ loading بقى محدود فـ الهيدر بَرك.
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccountHeader(
                name: _name,
                avatar: _buildAvatar(size: 44),
                isLoading: _isHeaderLoading,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.person_outline_rounded,
                      title: 'المعلومات الشخصية',
                      subtitle: 'الاسم، البريد الإلكتروني، رقم الهاتف',
                      featured: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PersonalInfoEditScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.lock_outline_rounded,
                      title: 'الخصوصية',
                      subtitle: 'من يمكنه رؤية محتواك',
                      onTap: _openSecurityPrivacy,
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      title: 'اللغة',
                      subtitle: 'العربية',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LanguageScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.brush_outlined,
                      title: 'المظهر',
                      subtitle: 'الوضع العادي / الفاتح',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AppearanceScreen(),
                        ),
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.logout_rounded,
                      title: 'تسجيل الخروج',
                      subtitle: 'الخروج من حسابك',
                      isDanger: true,
                      isLast: true,
                      onTap: _signOut,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(top: false, child: _buildBottomNav()),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(
            icon: Icons.home,
            label: 'الرئيسية',
            selected: false,
            onTap: () => Navigator.pop(context, 0),
          ),
          _navItem(
            icon: Icons.favorite,
            label: 'الإعجابات',
            selected: false,
            onTap: () => Navigator.pop(context, 1),
            badgeCount: _pendingInvitationsCount,
          ),
          _navItem(
            icon: Icons.chat,
            label: 'المحادثات',
            selected: false,
            onTap: () => Navigator.pop(context, 2),
            badgeCount: _unreadMessagesCount,
          ),
          _navItem(
            icon: Icons.person,
            label: 'حسابي',
            selected: true,
            onTap: () {},
            isProfile: true,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool isProfile = false,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              isProfile
                  ? Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? kGold : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(child: _buildAvatar(size: 28)),
                    )
                  : Icon(
                      icon,
                      color: selected ? kDarkGreen : Colors.grey.shade400,
                      size: 24,
                    ),
              if (badgeCount > 0)
                Positioned(
                  top: -6,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B7A), Color(0xFFDE3B40)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: badgeCount > 9
                          ? BoxShape.rectangle
                          : BoxShape.circle,
                      borderRadius: badgeCount > 9
                          ? BorderRadius.circular(9)
                          : null,
                      border: Border.all(color: Colors.white, width: 1.6),
                    ),
                    child: Center(
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              color: selected ? kDarkGreen : Colors.grey.shade400,
            ),
          ),
          // ✅ النقطة الذهبية تبان تحت أي عنصر مفعّل، بما فيه "حسابي"
          // (قبل، كانت مخبية غير على البروفايل بـ "!isProfile").
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: kGold,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// 🧩 HEADER — دابا كيقبل isLoading باش يبين skeleton خفيف
// (دائرة + خط رمادي) بلا ما يخبي الصفحة كاملها ولا bottom nav.
// ============================================================
class _AccountHeader extends StatelessWidget {
  final String name;
  final Widget avatar;
  final bool isLoading;

  const _AccountHeader({
    required this.name,
    required this.avatar,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: kGold, width: 2.6),
                ),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: kGold,
                            ),
                          )
                        : avatar,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading
                        ? Container(
                            width: 140,
                            height: 22,
                            decoration: BoxDecoration(
                              color: kDarkGreen.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          )
                        : Text(
                            name.isEmpty ? '—' : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                              color: kDarkGreen,
                              letterSpacing: -0.5,
                            ),
                          ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'استمتع برحلتك معنا',
                          style: TextStyle(
                            fontSize: 13.5,
                            color: kDarkGreen.withValues(alpha: 0.75),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.favorite_rounded,
                          size: 14,
                          color: kGold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool featured;
  final bool isDanger;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.featured = false,
    this.isDanger = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isDanger ? const Color(0xFFE0637A) : kDarkGreen;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: featured
                  ? Border.all(color: kGold.withValues(alpha: 0.35), width: 1.3)
                  : Border.all(color: Colors.black.withValues(alpha: 0.03)),
              boxShadow: [
                BoxShadow(
                  color: kDarkGreen.withValues(alpha: featured ? 0.09 : 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDanger
                          ? accent.withValues(alpha: 0.10)
                          : kDarkGreen.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: isDanger ? accent : kDarkGreen,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
