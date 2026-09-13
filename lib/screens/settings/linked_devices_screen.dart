// screens/settings/linked_devices_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/device_service.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class _DeviceInfo {
  final String id;
  final String name;
  final String platform;
  final Timestamp? lastActive;
  final bool isCurrent;

  const _DeviceInfo({
    required this.id,
    required this.name,
    required this.platform,
    required this.lastActive,
    required this.isCurrent,
  });

  IconData get icon {
    switch (platform) {
      case 'android':
        return Icons.smartphone_rounded;
      case 'ios':
        return Icons.phone_iphone_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  String get lastActiveLabel {
    if (isCurrent) return 'متصل الآن';
    if (lastActive == null) return '';
    final diff = DateTime.now().difference(lastActive!.toDate());
    if (diff.inMinutes < 1) return 'نشط الآن';
    if (diff.inMinutes < 60) return 'آخر نشاط قبل ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'آخر نشاط قبل ${diff.inHours} ساعة';
    return 'آخر نشاط قبل ${diff.inDays} يوم';
  }
}

class LinkedDevicesScreen extends StatefulWidget {
  const LinkedDevicesScreen({super.key});

  @override
  State<LinkedDevicesScreen> createState() => _LinkedDevicesScreenState();
}

class _LinkedDevicesScreenState extends State<LinkedDevicesScreen> {
  String? _currentDeviceId;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceId();
  }

  Future<void> _loadCurrentDeviceId() async {
    final id = await DeviceService.getDeviceId();
    if (mounted) setState(() => _currentDeviceId = id);
  }

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
      await DeviceService.signOutDevice(uid: _uid, deviceId: device.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: _currentDeviceId == null || _uid.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(color: kDarkGreen),
                )
              : StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .collection('devices')
                      .orderBy('lastActive', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final docs = snapshot.data?.docs ?? [];
                    final devices =
                        docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          return _DeviceInfo(
                            id: doc.id,
                            name: (data['name'] as String?) ?? 'جهاز غير معروف',
                            platform:
                                (data['platform'] as String?) ?? 'unknown',
                            lastActive: data['lastActive'] as Timestamp?,
                            isCurrent: doc.id == _currentDeviceId,
                          );
                        }).toList()..sort(
                          (a, b) => a.isCurrent ? -1 : (b.isCurrent ? 1 : 0),
                        );

                    return ListView(
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
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 26),
                        if (snapshot.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: kDarkGreen,
                              ),
                            ),
                          )
                        else if (devices.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Text(
                                'ماكاين حتى جهاز مسجل',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ),
                          )
                        else
                          for (final device in devices) ...[
                            _DeviceTile(
                              device: device,
                              onSignOut: () => _confirmSignOut(device),
                            ),
                            const SizedBox(height: 14),
                          ],
                      ],
                    );
                  },
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
                        device.isCurrent ? 'هاتفك الحالي' : device.name,
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
                if (device.isCurrent)
                  Text(
                    device.name,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                const SizedBox(height: 2),
                Text(
                  device.lastActiveLabel,
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
