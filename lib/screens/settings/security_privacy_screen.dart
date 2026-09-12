// screens/settings/security_privacy_screen.dart
//
// ✅ شاشة "الأمان والخصوصية": سهم رجوع دائري أعلى اليسار، شعار درع
// فـ الوسط محاط بلمعات، عنوان "الأمان والخصوصية" + وصف فرنسي، سطر
// ثاني "احم معلوماتك وحسابك" + وصف فرنسي، بعدها 3 كروت: كلمة
// المرور / الخصوصية / الأجهزة المرتبطة.
//
// ✅ ماعادش كتعتمد على widget/page_background_decor.dart (تحذفات) —
// الألوان وCircleIconButton دابا معرّفين محليا هنا. وحيدت أوراق
// LeafBranch من حوالين الدرع (كانت جايات من نفس الملف المحذوف).
//
// ✅ تعديلات جديدة:
// - زر الرجوع دابا مثبت فعليا عل اليسار (mainAxisAlignment.end فـ RTL).
// - تحيدات اللمعات الذهبية (auto_awesome) لي كانو حداء الدرع.
//
// ⚠️ ملاحظة: تشيلات من هنا كروت "التحقق بخطوتين" و"نشاط الجلسات"
// لأن الصفحة الحقيقية فـ التطبيق فيها غير 3 كروت. الملفات
// two_factor_auth_screen.dart و session_activity_screen.dart ماعادش
// مستعملين — يمكن تمسحهم من المشروع.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'change_password_screen.dart';
import 'privacy_settings_screen.dart';
import 'linked_devices_screen.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class SecurityPrivacyScreen extends StatelessWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // فـ RTL، end = يسار
                children: [
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const _ShieldBadge(),
              const SizedBox(height: 18),
              ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  colors: [kDarkGreen, kGold],
                ).createShader(rect),
                child: const Text(
                  'الأمان والخصوصية',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Votre sécurité et votre confidentialité',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              const Text(
                'احم معلوماتك وحسابك',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kDarkGreen,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Protégez vos informations et votre compte',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 26),
              _SettingsTile(
                icon: Icons.lock_rounded,
                titleAr: 'كلمة المرور',
                titleFr: 'Changer le mot de passe',
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
                titleAr: 'الخصوصية',
                titleFr: 'Confidentialité',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacySettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _SettingsTile(
                icon: Icons.phone_android_rounded,
                titleAr: 'الأجهزة المرتبطة',
                titleFr: 'Appareils connectés',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LinkedDevicesScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// 🛡️ شعار الدرع فـ الوسط: دائرة خلفية فاتحة، درع أخضر متدرج بقفل
// أبيض. (اللمعات الذهبية تحيدات بطلب المستخدم)
// ================================================================
class _ShieldBadge extends StatelessWidget {
  const _ShieldBadge();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  kGold.withValues(alpha: 0.16),
                  kDarkGreen.withValues(alpha: 0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            child: CustomPaint(
              size: const Size(72, 72),
              painter: _ShieldPainter(),
            ),
          ),
        ],
      ),
    );
  }
}

/// درع مرسوم يدويًا (Path) بلون أخضر متدرج + قفل أبيض فـ الوسط.
class _ShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final shieldPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.92, h * 0.16)
      ..lineTo(w * 0.92, h * 0.52)
      ..cubicTo(w * 0.92, h * 0.8, w * 0.72, h * 0.94, w * 0.5, h)
      ..cubicTo(w * 0.28, h * 0.94, w * 0.08, h * 0.8, w * 0.08, h * 0.52)
      ..lineTo(w * 0.08, h * 0.16)
      ..close();

    final shieldPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [const Color(0xFF1C5A42), const Color(0xFF0F3D2E)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(shieldPath, shieldPaint);

    // 🔒 القفل الأبيض فـ الوسط
    final lockBodyRect = Rect.fromLTWH(w * 0.36, h * 0.46, w * 0.28, h * 0.22);
    final lockBody = RRect.fromRectAndRadius(
      lockBodyRect,
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(lockBody, Paint()..color = Colors.white);

    final shacklePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    final shackleRect = Rect.fromLTWH(w * 0.4, h * 0.28, w * 0.2, h * 0.24);
    canvas.drawArc(shackleRect, 3.4, 3.1, false, shacklePaint);

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.56),
      w * 0.035,
      Paint()..color = const Color(0xFF0F3D2E),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================================================================
// 🃏 كارت واحد فـ اللائحة: أيقونة دائرية + عنوان عربي + وصف فرنسي
// + سهم "‹" يوصل للشاشة ديالو
// ================================================================
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String titleAr;
  final String titleFr;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.titleAr,
    required this.titleFr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
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
                width: 46,
                height: 46,
                alignment: Alignment.center,
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
                child: Icon(icon, color: kDarkGreen, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleAr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: kDarkGreen,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      titleFr,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: kDarkGreen.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
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