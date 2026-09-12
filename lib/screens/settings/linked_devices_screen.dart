// screens/settings/linked_devices_screen.dart
//
// ✅ شاشة "الأجهزة المرتبطة" — الوصول ليها من كارت "الأجهزة
// المرتبطة" فـ SecurityPrivacyScreen. لائحة الأجهزة اللي تسجل
// فيهم الدخول، مع تمييز الجهاز الحالي وزر تسجيل خروج للباقي.
//
// ✅ ماعادش كتعتمد على widget/page_background_decor.dart (تحذفات) —
// الألوان وCircleIconButton دابا معرّفين محليا هنا.
//
// ✅ تعديل جديد: زر الرجوع دابا مثبت فعليا عل اليسار (بدّلنا مكانو
// فـ الـ Row لآخر العناصر) — باقي العنوان مركّز بالضبط بفضل
// SizedBox(width: 44) اللي كتعادل حجم الزر.
//
// ⚠️ اللائحة هنا mock (بيانات وهمية) — فـ المشروع الحقيقي بدّلها
// بقراءة من Firestore (users/{uid}/devices) أو من الـ backend.

import 'package:flutter/material.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class _DeviceInfo {
  final String name;
  final String location;
  final String lastActive;
  final IconData icon;
  final bool isCurrent;

  const _DeviceInfo({
    required this.name,
    required this.location,
    required this.lastActive,
    required this.icon,
    this.isCurrent = false,
  });
}

class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  // TODO: بدّلها بقراءة حقيقية من Firestore/Backend
  final List<_DeviceInfo> _devices = const [
    _DeviceInfo(
      name: 'هاتفك الحالي',
      location: 'الجزائر العاصمة، الجزائر',
      lastActive: 'متصل الآن',
      icon: Icons.smartphone_rounded,
      isCurrent: true,
    ),
    _DeviceInfo(
      name: 'iPhone 13',
      location: 'البليدة، الجزائر',
      lastActive: 'آخر نشاط قبل يومين',
      icon: Icons.phone_iphone_rounded,
    ),
    _DeviceInfo(
      name: 'Chrome - Windows',
      location: 'قسنطينة، الجزائر',
      lastActive: 'آخر نشاط قبل أسبوع',
      icon: Icons.laptop_mac_rounded,
    ),
  ];

  Future<void> _confirmSignOut(_DeviceInfo device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'تسجيل الخروج من الجهاز',
          style: TextStyle(color: kDarkGreen, fontWeight: FontWeight.bold),
        ),
        content: Text('متأكد بغيتي تسجل الخروج من "${device.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _devices.remove(device));
      // TODO: نفّذ تسجيل الخروج الحقيقي من هاذ الجهاز (revoke session)
    }
  }

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
                children: [
                  const SizedBox(width: 44),
                  const Expanded(
                    child: _GradientTitle(text: 'الأجهزة المرتبطة'),
                  ),
                  _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.maybePop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'إدارة الأجهزة التي تم تسجيل دخولك منها',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 26),
              for (final device in _devices) ...[
                _DeviceTile(
                  device: device,
                  onSignOut: () => _confirmSignOut(device),
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final _DeviceInfo device;
  final VoidCallback onSignOut;

  const _DeviceTile({required this.device, required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: device.isCurrent
            ? Border.all(color: kGold.withValues(alpha: 0.35), width: 1.3)
            : Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withValues(alpha: device.isCurrent ? 0.10 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kDarkGreen.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(device.icon, color: kDarkGreen, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        device.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: kDarkGreen,
                        ),
                      ),
                    ),
                    if (device.isCurrent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: kDarkGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'هذا الجهاز',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  device.location,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 2),
                Text(
                  device.lastActive,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade400),
                ),
                if (!device.isCurrent) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onSignOut,
                    child: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// ✅ عنوان بتدرّج لوني (نفس هوية باقي شاشات "حسابي")
// ================================================================
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