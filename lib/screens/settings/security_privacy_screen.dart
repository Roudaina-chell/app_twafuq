// screens/settings/security_privacy_screen.dart
//
// ✅ شاشة "الأمان والخصوصية" — كيتفتح من كارت "الخصوصية" فـ شاشة
// الإعدادات. نفس بنية الكروت البيضاء لي فـ SettingsScreen، زائد:
// - بادج دائري أخضر غامق بعلامة ✓ فـ الوسط، بهالة كريمية خفيفة
//   ورايه (glow)
// - عنوان فرعي "حافظ على أمان حسابك" مع زخرفة نقط صغيرة يسارو
// - 5 كروت: كلمة المرور / التحقق بخطوتين / الخصوصية / الأجهزة
//   المرتبطة / نشاط الجلسات
// - زخرفة "تلة" خضراء خفيفة + أوراق فـ الزاوية السفلى اليسرى

import 'package:flutter/material.dart';

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Stack(
          children: [
            // ✅ زخرفة أسفل الشاشة: تلة خضراء خفيفة + أوراق فالركن
            Positioned(left: 0, right: 0, bottom: 0, child: _buildHillDecor()),
            Positioned(left: -14, bottom: -6, child: _buildLeafCluster()),
            Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
                    children: [
                      const SizedBox(height: 8),
                      _buildShieldBadge(),
                      const SizedBox(height: 18),
                      _buildSectionTitle(),
                      const SizedBox(height: 20),
                      _buildTile(
                        icon: Icons.lock_rounded,
                        title: 'كلمة المرور',
                        subtitle: 'قم بتغيير كلمة المرور الخاصة بك',
                        onTap: () {
                          // TODO: فتح شاشة تغيير كلمة المرور
                        },
                      ),
                      _buildTile(
                        icon: Icons.gpp_good_rounded,
                        title: 'التحقق بخطوتين',
                        subtitle: 'إضافة طبقة أمان إضافية',
                        onTap: () {
                          // TODO: فتح شاشة تفعيل التحقق بخطوتين
                        },
                      ),
                      _buildTile(
                        icon: Icons.notifications_rounded,
                        title: 'الخصوصية',
                        subtitle: 'إدارة من يمكنه رؤية معلوماتك',
                        onTap: () {
                          // TODO: فتح شاشة إعدادات من يرى معلوماتك
                        },
                      ),
                      _buildTile(
                        icon: Icons.smartphone_rounded,
                        title: 'الأجهزة المرتبطة',
                        subtitle: 'إدارة الأجهزة التي تم تسجيل دخولك منها',
                        onTap: () {
                          // TODO: فتح شاشة الأجهزة المرتبطة
                        },
                      ),
                      _buildTile(
                        icon: Icons.open_in_new_rounded,
                        title: 'نشاط الجلسات',
                        subtitle: 'عرض جميع الجلسات النشطة',
                        onTap: () {
                          // TODO: فتح شاشة نشاط الجلسات
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🔝 الهيدر: سهم رجوع + عنوان "الأمان والخصوصية" فـ الوسط — بـ
  // Row بدل Stack/Positioned (أضمن باش السهم يبان دايما)
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
                'الأمان والخصوصية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🛡️ بادج الدرع فـ الوسط — دائرة خضراء غامقة بعلامة ✓ بيضاء،
  // فوق هالة كريمية خفيفة (glow) أكبر منها
  // ============================================================
  Widget _buildShieldBadge() {
    return Center(
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.14),
              ),
            ),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: darkGreen,
                boxShadow: [
                  BoxShadow(
                    color: darkGreen.withValues(alpha: 0.30),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gpp_good_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✳️ العنوان الفرعي "حافظ على أمان حسابك" + زخرفة نقط صغيرة
  // ============================================================
  Widget _buildSectionTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildDotsDecor(),
        const SizedBox(width: 8),
        const Text(
          'حافظ على أمان حسابك',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: darkGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildDotsDecor() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: gold.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ⚙️ كارت واحد فـ الليستة — نفس ستايل SettingsScreen بالضبط
  // ============================================================
  Widget _buildTile({
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
  // 🏞️ زخرفة "تلة" خضراء خفيفة تمتد بعرض الشاشة كاملة أسفلها
  // ============================================================
  Widget _buildHillDecor() {
    return IgnorePointer(
      child: ClipRect(
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(120),
              ),
              color: darkGreen.withValues(alpha: 0.06),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🍃 حزمة أوراق فـ الركن السفلي الأيسر (بحال التصميم المرجعي)
  // ============================================================
  Widget _buildLeafCluster() {
    return IgnorePointer(
      child: SizedBox(
        width: 130,
        height: 130,
        child: Stack(
          children: [
            Positioned(
              left: 6,
              bottom: 10,
              child: Transform.rotate(
                angle: -0.5,
                child: Icon(
                  Icons.eco_rounded,
                  size: 70,
                  color: darkGreen.withValues(alpha: 0.55),
                ),
              ),
            ),
            Positioned(
              left: 46,
              bottom: 4,
              child: Transform.rotate(
                angle: 0.35,
                child: Icon(
                  Icons.eco_rounded,
                  size: 46,
                  color: darkGreen.withValues(alpha: 0.35),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
