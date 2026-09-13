// screens/settings/privacy_settings_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

const double kSettingsBadgeSize = 84;
const double kSettingsBadgeIconSize = 36;

enum OnlineDuration { oneHour, oneDay, sevenDays, always }

extension OnlineDurationX on OnlineDuration {
  String get label {
    switch (this) {
      case OnlineDuration.oneHour:
        return 'ساعة واحدة';
      case OnlineDuration.oneDay:
        return '24 ساعة';
      case OnlineDuration.sevenDays:
        return '7 أيام';
      case OnlineDuration.always:
        return 'دائماً';
    }
  }

  Duration? get value {
    switch (this) {
      case OnlineDuration.oneHour:
        return const Duration(hours: 1);
      case OnlineDuration.oneDay:
        return const Duration(hours: 24);
      case OnlineDuration.sevenDays:
        return const Duration(days: 7);
      case OnlineDuration.always:
        return null;
    }
  }
}

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _isLoading = true;
  bool _showOnlineStatus = false;
  DateTime? _onlineStatusUntil;
  bool _saving = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
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
      final untilRaw = data['onlineStatusUntil'] as String?;
      final until = (untilRaw != null && untilRaw.isNotEmpty)
          ? DateTime.tryParse(untilRaw)
          : null;
      final expired = until != null && until.isBefore(DateTime.now());

      setState(() {
        _showOnlineStatus =
            (data['showOnlineStatus'] as bool? ?? false) && !expired;
        _onlineStatusUntil = expired ? null : until;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _persist({required bool show, required DateTime? until}) async {
    if (_uid.isEmpty) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(_uid).set({
        'showOnlineStatus': show,
        'onlineStatusUntil': until?.toIso8601String(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      setState(() {
        _showOnlineStatus = show;
        _onlineStatusUntil = until;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وقع خطأ أثناء الحفظ، عاود المحاولة')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onToggle(bool value) async {
    if (!value) {
      await _persist(show: false, until: null);
      return;
    }
    final choice = await _pickDuration();
    if (choice == null) return;
    final until = choice.value == null
        ? null
        : DateTime.now().add(choice.value!);
    await _persist(show: true, until: until);
  }

  Future<void> _extend() async {
    final choice = await _pickDuration();
    if (choice == null) return;
    final until = choice.value == null
        ? null
        : DateTime.now().add(choice.value!);
    await _persist(show: true, until: until);
  }

  Future<OnlineDuration?> _pickDuration() {
    return showModalBottomSheet<OnlineDuration>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'مدة إظهار حالة الاتصال',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: kDarkGreen,
                ),
              ),
              const SizedBox(height: 16),
              ...OnlineDuration.values.map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: kMint.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, d),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          d.label,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: kDarkGreen,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _remainingLabel() {
    if (!_showOnlineStatus) return null;
    if (_onlineStatusUntil == null) return 'مفعّلة بشكل دائم';
    final remaining = _onlineStatusUntil!.difference(DateTime.now());
    if (remaining.isNegative) return null;
    if (remaining.inHours >= 24) {
      final days = (remaining.inHours / 24).ceil();
      return 'متبقي تقريباً $days أيام';
    }
    if (remaining.inHours >= 1) {
      return 'متبقي تقريباً ${remaining.inHours} ساعة';
    }
    return 'متبقي أقل من ساعة';
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
                      width: kSettingsBadgeSize,
                      height: kSettingsBadgeSize,
                      decoration: BoxDecoration(
                        color: kDarkGreen.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.privacy_tip_rounded,
                        color: kDarkGreen,
                        size: kSettingsBadgeIconSize,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'الخصوصية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kDarkGreen,
                        letterSpacing: -0.4,
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
                subtitle: _remainingLabel() ?? 'يظهر للآخرين إذا كنت متصل الآن',
                value: _showOnlineStatus,
                saving: _saving,
                onChanged: _saving ? null : _onToggle,
              ),
              if (_showOnlineStatus) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _saving ? null : _extend,
                    icon: const Icon(
                      Icons.timer_outlined,
                      size: 18,
                      color: kDarkGreen,
                    ),
                    label: const Text(
                      'تمديد المدة',
                      style: TextStyle(
                        color: kDarkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
  final bool saving;
  final ValueChanged<bool>? onChanged;

  const _PrivacySwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.saving,
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
              color: kDarkGreen.withValues(alpha: 0.08),
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
          if (saving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: kDarkGreen,
              ),
            )
          else
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
