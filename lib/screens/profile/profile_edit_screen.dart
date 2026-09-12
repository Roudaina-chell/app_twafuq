// screens/profile/profile_edit_screen.dart
//
// صفحة "حسابي" — تصميم v2: نفس لغة التصميم المستعملة فـ باقي التطبيق
// بالضبط (هيدر بتدرّج خفيف + حلقة ذهبية حول الصورة + عنوان بتدرّج لوني
// + بطاقات بظلال ناعمة وأيقونات دائرية بتدرّج + شريط سفلي مطابق
// حرفياً لشريط الرئيسية، بلا اختلاف فـ العناصر ولا الترتيب).
//
// ✅ الضغط على "المعلومات الشخصية" يودّي لـ PersonalInfoEditScreen.
// ✅ الضغط على "الخصوصية" كيودّي لـ SecurityPrivacyScreen.
// ✅ الضغط على تبويب "الرئيسية/الإعجابات/المحادثات" فـ الشريط السفلي
//    كيرجع لصفحة الرئيسية ويبدّل التبويب المطلوب فعلياً (Navigator.pop
//    برجوع رقم التبويب، تقرأه home_screen.dart وتبدّل _selectedIndex).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'personal_info_edit_screen.dart';
import '../settings/appearance_screen.dart';
import '../settings/language_screen.dart';
import '../settings/security_privacy_screen.dart';

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
  bool _isLoading = true;
  String _name = '';
  String? _avatarAsset;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    try {
      if (_uid.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final data = doc.data() ?? {};

      setState(() {
        _name =
            (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
        _avatarAsset =
            (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildAvatar({double size = 46}) {
    if (_avatarAsset == null || _avatarAsset!.trim().isEmpty) {
      return Icon(Icons.person, size: size, color: kDarkGreen);
    }
    final isNetwork =
        _avatarAsset!.startsWith('http://') ||
        _avatarAsset!.startsWith('https://');
    final image = isNetwork
        ? Image.network(
            _avatarAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) =>
                Icon(Icons.person, size: size, color: kDarkGreen),
          )
        : Image.asset(
            _avatarAsset!,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (c, e, s) =>
                Icon(Icons.person, size: size, color: kDarkGreen),
          );
    return ClipOval(child: image);
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // ⚠️ بدّل الـ route هنا بالمسار الحقيقي لصفحة تسجيل الدخول عندك
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _openSecurityPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SecurityPrivacyScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator(color: kDarkGreen)),
      );
    }

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
                onBack: () => Navigator.maybePop(context),
                onSettings: () {
                  // TODO: اربطها بصفحة الإعدادات المتقدمة إذا كانت موجودة
                },
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: _AccountBottomNav(avatar: _buildAvatar(size: 26)),
      ),
    );
  }
}

// ================================================================
// ✅ رأس الصفحة: نفس لغة هيدرات باقي الصفحات (تدرّج خفيف + حلقة
// ذهبية حول الصورة + عنوان بتدرّج لوني ShaderMask)
// ================================================================
class _AccountHeader extends StatelessWidget {
  final String name;
  final Widget avatar;
  final VoidCallback onBack;
  final VoidCallback onSettings;

  const _AccountHeader({
    required this.name,
    required this.avatar,
    required this.onBack,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGold.withValues(alpha: 0.10), kBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(icon: Icons.arrow_back, onTap: onBack),
              _CircleIconButton(
                icon: Icons.settings_outlined,
                onTap: onSettings,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                width: 100,
                height: 100,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [kGold, kDarkGreenLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
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
                    child: avatar,
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [kDarkGreen, kGold],
                      ).createShader(rect),
                      child: Text(
                        name.isEmpty ? '—' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
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
          child: Icon(icon, color: kDarkGreen, size: 20),
        ),
      ),
    );
  }
}

// ================================================================
// ✅ صف واحد من لائحة الإعدادات: أيقونة بتدرّج + عنوان + وصف + سهم
// featured=true → العنصر الأول: حد ذهبي مميّز
// isDanger=true → لون أحمر (تسجيل الخروج)
// ================================================================
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
                      gradient: LinearGradient(
                        colors: isDanger
                            ? [accent.withValues(alpha: 0.16), accent.withValues(alpha: 0.06)]
                            : [kGold.withValues(alpha: 0.20), kDarkGreen.withValues(alpha: 0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
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

// ================================================================
// ✅ الشريط السفلي — مطابق حرفياً لشريط الرئيسية (نفس الحاوية العائمة،
// نفس الظل، نفس الـ4 عناصر بنفس الترتيب). تبويب "حسابي" هو المفعّل،
// وباقي التبويبات كترجع لصفحة الرئيسية وتبدّل التبويب فعلياً هناك
// (عبر Navigator.pop مع رقم التبويب).
// ================================================================
class _AccountBottomNav extends StatelessWidget {
  final Widget avatar;

  const _AccountBottomNav({required this.avatar});

  @override
  Widget build(BuildContext context) {
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
          _navItem(context, Icons.home, 'الرئيسية', false, targetIndex: 0),
          _navItem(context, Icons.favorite, 'الإعجابات', false, targetIndex: 1),
          _navItem(context, Icons.chat, 'المحادثات', false, targetIndex: 2),
          _navItem(context, Icons.person, 'حسابي', true, isProfile: true),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    bool selected, {
    int? targetIndex,
    bool isProfile = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (targetIndex != null) Navigator.pop(context, targetIndex);
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          isProfile
              ? Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: kGold, width: 2),
                  ),
                  child: ClipOval(child: avatar),
                )
              : Icon(
                  icon,
                  color: selected ? kDarkGreen : Colors.grey.shade400,
                  size: 24,
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
          if (selected)
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 6,
              height: 6,
              decoration: const BoxDecoration(color: kGold, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}