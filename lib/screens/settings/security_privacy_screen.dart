// screens/settings/security_privacy_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'blocked_list_screen.dart';

// محتفظ بها للتوافق مع ملفات أخرى قد تستوردها
const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

const double kSettingsBadgeSize = 84;
const double kSettingsBadgeIconSize = 36;

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: p.bg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const _SecurityBadge(),
              const SizedBox(height: 16),
              Text(
                'الأمان والخصوصية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: p.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'احم معلوماتك وحسابك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: p.subtitle),
              ),
              const SizedBox(height: 26),
              _SettingsTile(
                icon: Icons.lock_rounded,
                title: 'كلمة المرور',
                subtitle: 'قم بتحديث كلمة المرور الخاصة بك',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.verified_user_rounded,
                title: 'الخصوصية',
                subtitle: 'تحكم في من يرى معلوماتك',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.block_rounded,
                title: 'المستخدمون المحظورون',
                subtitle: 'إدارة قائمة المستخدمين الذين قمت بحظرهم',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BlockedListScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityBadge extends StatelessWidget {
  const _SecurityBadge();

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Center(
      child: Container(
        width: kSettingsBadgeSize,
        height: kSettingsBadgeSize,
        decoration: BoxDecoration(
          color: p.primary.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.gpp_good_rounded,
          color: p.primary,
          size: kSettingsBadgeIconSize,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: p.isDark ? p.border : Colors.black.withValues(alpha: 0.03),
            ),
            boxShadow: p.shadow(),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: p.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: p.primary, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: p.primary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: p.primary.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: p.primary.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
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
  final Color bg;
  final Color card;
  final Color border;
  final Color subtitle;

  const _Pal._({
    required this.isDark,
    required this.primary,
    required this.bg,
    required this.card,
    required this.border,
    required this.subtitle,
  });

  factory _Pal.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return _Pal._(
      isDark: isDark,
      primary: primary,
      bg: theme.scaffoldBackgroundColor,
      card: theme.colorScheme.surface,
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFEFEAE2),
      subtitle: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
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
