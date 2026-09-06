// screens/settings/settings_screen.dart
//
// ✅ شاشة "الإعدادات" — بحال التصميم المرجعي:
// سهم رجوع + عنوان "الإعدادات" فـ الوسط، بطاقة خضراء غامقة فوق
// فيها أفاتار المستخدم + الاسم + المهنة + زر أبيض "تعديل الملف
// الشخصي"، وتحتها ليستة كروت بيضاء منفصلة (كل وحدة: أيقونة دائرية
// + عنوان + وصف قصير + سهم)، مربوطة بـ Firestore الحقيقي باش تجيب
// الاسم/الصورة/المهنة ديال المستخدم.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../profile/profile_edit_screen.dart';
import 'security_privacy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  bool _isLoading = true;
  String _userName = '';
  String? _avatarAsset;
  String? _profession;
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ============================================================
  // ✅ نجيبو الاسم/الصورة/المهنة الحقيقيين من collection('users')
  // ============================================================
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _userName =
            (data?['fullName'] as String?) ??
            (data?['name'] as String?) ??
            user.displayName ??
            'مستخدم';
        _avatarAsset =
            (data?['avatarAsset'] as String?) ??
            (data?['avatarPath'] as String?);
        _profession =
            (data?['profession'] as String?) ?? (data?['interest'] as String?);
        _isOnline = data?['isOnline'] as bool? ?? true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Settings: user data load failed: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openProfileEdit() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
    );
    if (!mounted) return;
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Stack(
                children: [
                  // ✅ زخرفة أوراق خضراء خفيفة أسفل الشاشة (بحال
                  // التصميم المرجعي)
                  Positioned(
                    left: -18,
                    bottom: -10,
                    child: _buildLeafDecor(size: 110, angle: -0.35),
                  ),
                  Positioned(
                    right: -22,
                    bottom: 40,
                    child: _buildLeafDecor(size: 90, angle: 0.5),
                  ),
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 18),
                      _buildSettingsTile(
                        icon: Icons.person_rounded,
                        title: 'المعلومات الشخصية',
                        subtitle: 'الاسم، البريد، رقم الهاتف',
                        onTap: () {
                          // TODO: فتح شاشة تعديل المعلومات الشخصية
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.lock_rounded,
                        title: 'الخصوصية',
                        subtitle: 'من يمكنه رؤية محتواك',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SecurityPrivacyScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.notifications_rounded,
                        title: 'الإشعارات',
                        subtitle: 'صوت، اهتزاز، إشعارات التطبيق',
                        onTap: () {
                          // TODO: فتح شاشة إعدادات الإشعارات
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.brightness_6_rounded,
                        title: 'المظهر',
                        subtitle: 'الوضع الليلي/الفاتح',
                        onTap: () {
                          // TODO: فتح شاشة إعدادات المظهر
                        },
                      ),
                      _buildSettingsTile(
                        icon: Icons.translate_rounded,
                        title: 'اللغة',
                        subtitle: 'العربية',
                        onTap: () {
                          // TODO: فتح شاشة اختيار اللغة
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔝 الهيدر: سهم رجوع + عنوان "الإعدادات" فـ الوسط — بـ Row
  // بدل Stack/Positioned (أضمن باش السهم يبان دايما ما يختفيش)
  // ============================================================
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: darkGreen,
                size: 24,
              ),
              splashRadius: 22,
              onPressed: () => Navigator.maybePop(context),
            ),
            const Expanded(
              child: Text(
                'الإعدادات',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                ),
              ),
            ),
            // ✅ سبيسر بحجم زر السهم باش العنوان يبقى مركّز بالضبط
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🟢 بطاقة الملف الشخصي — خضراء غامقة، أفاتار + اسم + مهنة
  // + زر أبيض "تعديل الملف الشخصي"
  // ============================================================
  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: darkGreen,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // ✅ زخرفة ورقة خفيفة فوق يمين البطاقة
          Positioned(
            top: -10,
            right: -10,
            child: _buildLeafDecor(size: 80, angle: 0.2, opacity: 0.10),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          child: ClipOval(
                            child: _isLoading
                                ? Container(color: Colors.white24)
                                : (_avatarAsset == null ||
                                          _avatarAsset!.trim().isEmpty
                                      ? Icon(
                                          Icons.person,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          size: 30,
                                        )
                                      : (_avatarAsset!.startsWith('http')
                                            ? Image.network(
                                                _avatarAsset!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.person,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      size: 30,
                                                    ),
                                              )
                                            : Image.asset(
                                                _avatarAsset!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Icon(
                                                      Icons.person,
                                                      color: Colors.white
                                                          .withValues(
                                                            alpha: 0.7,
                                                          ),
                                                      size: 30,
                                                    ),
                                              ))),
                          ),
                        ),
                        if (_isOnline)
                          Positioned(
                            bottom: 1,
                            right: 1,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.green.shade400,
                                shape: BoxShape.circle,
                                border: Border.all(color: darkGreen, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLoading ? '...' : _userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          if (!_isLoading &&
                              _profession != null &&
                              _profession!.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: gold),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(
                                    _profession!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _openProfileEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'تعديل الملف الشخصي',
                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
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

  // ============================================================
  // ⚙️ عنصر واحد فـ ليستة الإعدادات — كارت أبيض منفصل: أيقونة
  // دائرية + عنوان + وصف قصير + سهم فالجهة الأخرى
  // ============================================================
  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: darkGreen.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: darkGreen, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: darkGreen,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: Colors.grey.shade300,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🍃 زخرفة ورقة بسيطة (أيقونات متراكبة) كتعطي إحساس نباتي خفيف
  // بحال التصميم المرجعي، بلا الحاجة لصورة خارجية
  // ============================================================
  Widget _buildLeafDecor({
    required double size,
    double angle = 0,
    double opacity = 0.06,
  }) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Icon(Icons.eco_rounded, size: size, color: darkGreen),
        ),
      ),
    );
  }
}
