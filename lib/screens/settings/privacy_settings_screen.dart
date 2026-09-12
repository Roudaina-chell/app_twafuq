// screens/settings/privacy_settings_screen.dart
//
// شاشة "الخصوصية" — يتم فتحها من داخل security_privacy_screen.dart
// عبر الضغط على عنصر "الخصوصية".
//
// ✅ تبسيط: بقا غير خيار واحد — "إظهار حالة الاتصال" (online status).
// تشالو الخيارات الأخرى (الملف الشخصي للجميع / آخر ظهور / الرسائل
// من أي شخص) بطلب مباشر.
//
// ✅ ماعادش كتعتمد على widget/page_background_decor.dart —
// الألوان وCircleIconButton معرّفين محليا هنا.

import 'package:flutter/material.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _showOnlineStatus = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            kGold.withValues(alpha: 0.20),
                            kDarkGreen.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        color: kDarkGreen,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ShaderMask(
                      shaderCallback: (rect) => const LinearGradient(
                        colors: [kDarkGreen, kGold],
                      ).createShader(rect),
                      child: const Text(
                        'الخصوصية',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تحكم فيما يمكن للآخرين رؤيته',
                      style: TextStyle(
                        fontSize: 13,
                        color: kDarkGreen.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _PrivacySwitchTile(
                icon: Icons.circle,
                title: 'إظهار حالة الاتصال',
                subtitle: 'يظهر للآخرين إذا كنت متصل الآن',
                value: _showOnlineStatus,
                onChanged: (v) => setState(() => _showOnlineStatus = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacySwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

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
            color: kDarkGreen.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  kGold.withValues(alpha: 0.20),
                  kDarkGreen.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: kDarkGreen, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: kDarkGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    color: kDarkGreen.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: kDarkGreen,
            activeTrackColor: kMint,
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ✅ زر دائري (رجوع) — معرّف محليا، بلا اعتماد على أي ملف مشترك
// ================================================================
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
          child: Icon(icon, color: kDarkGreen, size: 20),
        ),
      ),
    );
  }
}