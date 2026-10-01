// screens/profile/avatar_picker_screen.dart
import 'package:flutter/material.dart';

/// شيت اختيار/تبديل الأفاتار — modal bottom sheet فوق نفس الصفحة.
///
/// الاستعمال:
/// ```dart
/// final selected = await showAvatarPicker(
///   context,
///   gender: _gender,
///   currentAvatarPath: _avatarAsset,
/// );
/// ```
Future<String?> showAvatarPicker(
  BuildContext context, {
  required String gender,
  String? currentAvatarPath,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AvatarPickerSheet(
      gender: gender,
      currentAvatarPath: currentAvatarPath,
    ),
  );
}

class _AvatarPickerSheet extends StatefulWidget {
  final String gender; // 'male' | 'female'
  final String? currentAvatarPath;

  const _AvatarPickerSheet({required this.gender, this.currentAvatarPath});

  @override
  State<_AvatarPickerSheet> createState() => _AvatarPickerSheetState();
}

class _AvatarPickerSheetState extends State<_AvatarPickerSheet> {
  int? _selectedIndex;

  final List<_AvatarOption> _femaleAvatars = const [
    _AvatarOption(
      id: 'f_1',
      assetPath: 'assets/avatars/female/female_1.png',
      bgColor: Color(0xFFFCE4EC),
    ),
    _AvatarOption(
      id: 'f_2',
      assetPath: 'assets/avatars/female/female_2.png',
      bgColor: Color(0xFFFFF3E0),
    ),
    _AvatarOption(
      id: 'f_3',
      assetPath: 'assets/avatars/female/female_3.png',
      bgColor: Color(0xFFF3E5F5),
    ),
    _AvatarOption(
      id: 'f_4',
      assetPath: 'assets/avatars/female/female_4.png',
      bgColor: Color(0xFFE8F5E9),
    ),
    _AvatarOption(
      id: 'f_5',
      assetPath: 'assets/avatars/female/female_5.png',
      bgColor: Color(0xFFE0F7FA),
    ),
    _AvatarOption(
      id: 'f_6',
      assetPath: 'assets/avatars/female/female_6.png',
      bgColor: Color(0xFFFFF8E1),
    ),
  ];

  final List<_AvatarOption> _maleAvatars = const [
    _AvatarOption(
      id: 'm_1',
      assetPath: 'assets/avatars/male/male_1.png',
      bgColor: Color(0xFFE3F2FD),
    ),
    _AvatarOption(
      id: 'm_2',
      assetPath: 'assets/avatars/male/male_2.png',
      bgColor: Color(0xFFFFF3E0),
    ),
    _AvatarOption(
      id: 'm_3',
      assetPath: 'assets/avatars/male/male_3.png',
      bgColor: Color(0xFFEDE7F6),
    ),
    _AvatarOption(
      id: 'm_4',
      assetPath: 'assets/avatars/male/male_4.png',
      bgColor: Color(0xFFE8F5E9),
    ),
    _AvatarOption(
      id: 'm_5',
      assetPath: 'assets/avatars/male/male_5.png',
      bgColor: Color(0xFFEFEBE9),
    ),
    _AvatarOption(
      id: 'm_6',
      assetPath: 'assets/avatars/male/male_6.png',
      bgColor: Color(0xFFECEFF1),
    ),
  ];

  List<_AvatarOption> get _avatars =>
      widget.gender == 'male' ? _maleAvatars : _femaleAvatars;

  @override
  void initState() {
    super.initState();
    if (widget.currentAvatarPath != null) {
      final idx = _avatars.indexWhere(
        (a) => a.assetPath == widget.currentAvatarPath,
      );
      if (idx != -1) _selectedIndex = idx;
    }
  }

  void _confirm() {
    if (_selectedIndex == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, _avatars[_selectedIndex!].assetPath);
  }

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);
    final canSave = _selectedIndex != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: p.handle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 34),
                    Expanded(
                      child: Text(
                        'تغيير الصورة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.primary,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: p.card,
                          shape: BoxShape.circle,
                          boxShadow: p.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: p.primary.withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: p.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Text(
                  'اختاري الأفاتار متاعك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: p.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'هاذ الأفاتار غادي يبان فـ ملفك الشخصي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.subtitle,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 22),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _avatars.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 6,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final avatar = _avatars[index];
                    final bool selected = _selectedIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIndex = index),
                      child: AnimatedScale(
                        scale: selected ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: Center(
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: avatar.bgColor,
                                  border: Border.all(
                                    color: selected ? p.gold : p.card,
                                    width: selected ? 4 : 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: selected
                                          ? p.gold.withValues(alpha: 0.40)
                                          : Colors.black.withValues(
                                              alpha: p.isDark ? 0.30 : 0.08,
                                            ),
                                      blurRadius: selected ? 16 : 8,
                                      spreadRadius: selected ? 1.5 : 0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: SizedBox.expand(
                                    child: Image.asset(
                                      avatar.assetPath,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: avatar.bgColor,
                                          alignment: Alignment.center,
                                          // الخلفية باستيل دايماً → أيقونة غامقة ثابتة
                                          child: const Icon(
                                            Icons.person,
                                            size: 36,
                                            color: Color(0xFF0F3D2E),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              if (selected)
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: p.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: p.bg, width: 2),
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: p.onPrimary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 22),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 54,
                  decoration: BoxDecoration(
                    color: canSave ? p.primary : p.disabled,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: canSave && !p.isDark
                        ? [
                            BoxShadow(
                              color: p.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: canSave ? _confirm : null,
                      borderRadius: BorderRadius.circular(18),
                      child: Center(
                        child: Text(
                          'حفظ',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: canSave ? p.onPrimary : p.disabledText,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AvatarOption {
  final String id;
  final String assetPath;
  final Color bgColor;

  const _AvatarOption({
    required this.id,
    required this.assetPath,
    required this.bgColor,
  });
}

// ---------------------------------------------------------------------------
// ألوان مشتقة من الـ Theme الحالي (نهاري / ليلي) — خاصة بهذا الملف
// ---------------------------------------------------------------------------
class _Pal {
  final bool isDark;
  final Color primary;
  final Color onPrimary;
  final Color bg;
  final Color card;
  final Color subtitle;
  final Color handle;
  final Color disabled;
  final Color disabledText;
  final Color gold;

  const _Pal._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.bg,
    required this.card,
    required this.subtitle,
    required this.handle,
    required this.disabled,
    required this.disabledText,
    required this.gold,
  });

  factory _Pal.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return _Pal._(
      isDark: isDark,
      primary: theme.colorScheme.primary,
      onPrimary: theme.colorScheme.onPrimary,
      bg: theme.scaffoldBackgroundColor,
      card: theme.colorScheme.surface,
      subtitle: isDark ? Colors.grey.shade400 : Colors.black45,
      handle: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
      disabled: isDark ? const Color(0xFF2A3A33) : Colors.grey.shade300,
      disabledText: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
      gold: const Color(0xFFC9A24B),
    );
  }
}
