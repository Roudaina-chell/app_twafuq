// screens/profile/personal_info_edit_screen.dart
//
// ✅ حيّدت زخرفة خلفية الصفحة الكاملة (_PageBackgroundDecor: فروع
// الورق فـ الزوايا + الخيوط الذهبية المنحنية) — دابا خلفية بسيطة
// (kBg). بقاو فرعي الورق حول الأفاتار وفرع الزاوية فوق كل بطاقة
// (هوما جزء من تصميم العنصر نفسه، ماشي "خلفية").
//
// المنطق (تعديل inline لكل حقل + ✅ حفظ / ❌ إلغاء) بقى بلا تغيير.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'avatar_selection.dart';

// ============================================================
// ✅ نفس هوية الألوان متاع صفحة الحساب
// ============================================================
const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kMidGreen = Color(0xFF1A6B4A);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);

class PersonalInfoEditScreen extends StatefulWidget {
  const PersonalInfoEditScreen({super.key});

  @override
  State<PersonalInfoEditScreen> createState() => _PersonalInfoEditScreenState();
}

class _PersonalInfoEditScreenState extends State<PersonalInfoEditScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // القيم الحالية (لي كتبان فـ الصفحة)
  String _fullName = '';
  DateTime? _birthDate;
  String _occupation = '';
  String? _educationLevel;
  String? _city;
  String? _maritalStatus;
  String _bio = '';
  String? _avatarAsset;

  int? _ageMin;
  int? _ageMax;
  String? _prefCity;

  final List<String> _educationLevels = [
    'ثانوي',
    'ليسانس',
    'ماستر',
    'دكتوراه',
    'أخرى',
  ];
  final List<String> _cities = [
    'الجزائر العاصمة',
    'وهران',
    'قسنطينة',
    'قالمة',
    'عنابة',
    'البليدة',
    'أخرى',
  ];
  final List<String> _maritalStatuses = ['أعزب', 'مطلق', 'أرمل'];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      if (_uid.isEmpty) {
        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
          _isLoading = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .get();
      final data = doc.data() ?? {};
      final preferences = (data['preferences'] as Map<String, dynamic>?) ?? {};

      final rawBirth = data['birthDate'] as String?;

      setState(() {
        _fullName =
            (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
        _occupation =
            (data['occupation'] as String?) ?? (data['job'] as String?) ?? '';
        _bio = (data['bio'] as String?) ?? (data['about'] as String?) ?? '';
        _birthDate = (rawBirth != null && rawBirth.isNotEmpty)
            ? DateTime.tryParse(rawBirth)
            : null;
        _educationLevel = data['educationLevel'] as String?;
        _city = data['city'] as String?;
        _maritalStatus = data['maritalStatus'] as String?;
        // ✅ Fallback: بعض الحسابات القديمة تخزنو تحت "avatarPath" بدل
        // "avatarAsset" (نسخة قديمة من avatar_selection.dart). نقرا
        // الحقلين بجوج باش ما يبقاش حتى حساب بلا أفاتار.
        _avatarAsset =
            (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
        _ageMin = preferences['ageMin'] as int?;
        _ageMax = preferences['ageMax'] as int?;
        _prefCity =
            (preferences['city'] as String?) ??
            (preferences['wilaya'] as String?);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'وقع خطأ فـ تحميل المعلومات';
        _isLoading = false;
      });
    }
  }

  int? _computeAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day))
      age--;
    return age;
  }

  // ============================================================
  // ✅ يكتب حقل واحد بروحو فـ Firestore بـ merge:true (بلا ما يلمس الباقي)
  // ============================================================
  Future<bool> _saveField(Map<String, dynamic> payload) async {
    try {
      if (_uid.isEmpty) return false;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .set(payload, SetOptions(merge: true));
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('وقع خطأ أثناء الحفظ، عاود المحاولة')),
        );
      }
      return false;
    }
  }

  Future<void> _changeAvatar() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
    );
    if (!mounted) return;
    await _loadProfile();
  }

  // ============================================================
  // ✅ صورة الأفاتار — تدعم رابط شبكة (Firebase Storage) و asset محلي
  // ============================================================
  static Widget _buildAvatarImage({
    required String? source,
    required double size,
  }) {
    if (source == null || source.trim().isEmpty) {
      return const Icon(Icons.person, size: 56, color: kDarkGreen);
    }
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    return isNetwork
        ? Image.network(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) {
              debugPrint('❌ Avatar (network) load failed: $source -> $error');
              return const Icon(Icons.person, size: 56, color: kDarkGreen);
            },
          )
        : Image.asset(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) {
              debugPrint('❌ Avatar (asset) load failed: $source -> $error');
              return const Icon(Icons.person, size: 56, color: kDarkGreen);
            },
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
              _EditHeader(
                onBack: () => Navigator.maybePop(context),
                onTapAvatar: _changeAvatar,
                avatarChild: _buildAvatarImage(source: _avatarAsset, size: 94),
                name: _fullName,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // بطاقة المعلومات الأساسية
                    _Card(
                      title: 'المعلومات الأساسية',
                      icon: Icons.badge_outlined,
                      children: [
                        InlineTextField(
                          label: 'الاسم الكامل',
                          icon: Icons.person_outline_rounded,
                          value: _fullName,
                          onSave: (v) async {
                            final ok = await _saveField({'fullName': v});
                            if (ok) setState(() => _fullName = v);
                            return ok;
                          },
                        ),
                        InlineDateField(
                          label: 'تاريخ الميلاد',
                          value: _birthDate,
                          onSave: (d) async {
                            final ok = await _saveField({
                              'birthDate': d.toIso8601String(),
                              'age': _computeAge(d),
                            });
                            if (ok) setState(() => _birthDate = d);
                            return ok;
                          },
                        ),
                        InlineTextField(
                          label: 'المهنة',
                          icon: Icons.work_outline,
                          value: _occupation,
                          onSave: (v) async {
                            final ok = await _saveField({'occupation': v});
                            if (ok) setState(() => _occupation = v);
                            return ok;
                          },
                        ),
                        InlineDropdownField(
                          label: 'المستوى التعليمي',
                          icon: Icons.school_outlined,
                          value: _educationLevel,
                          options: _educationLevels,
                          onSave: (v) async {
                            final ok = await _saveField({'educationLevel': v});
                            if (ok) setState(() => _educationLevel = v);
                            return ok;
                          },
                        ),
                        InlineDropdownField(
                          label: 'المدينة',
                          icon: Icons.location_on_outlined,
                          value: _city,
                          options: _cities,
                          onSave: (v) async {
                            final ok = await _saveField({'city': v});
                            if (ok) setState(() => _city = v);
                            return ok;
                          },
                        ),
                        InlineDropdownField(
                          label: 'الحالة العائلية',
                          icon: Icons.people_outline,
                          value: _maritalStatus,
                          options: _maritalStatuses,
                          onSave: (v) async {
                            final ok = await _saveField({'maritalStatus': v});
                            if (ok) setState(() => _maritalStatus = v);
                            return ok;
                          },
                        ),
                        InlineTextField(
                          label: 'نبذة عني',
                          icon: Icons.info_outline_rounded,
                          value: _bio,
                          maxLines: 4,
                          maxLength: 300,
                          onSave: (v) async {
                            final ok = await _saveField({'bio': v});
                            if (ok) setState(() => _bio = v);
                            return ok;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // بطاقة التفضيلات
                    _Card(
                      title: 'تفضيلات البحث',
                      icon: Icons.tune_rounded,
                      children: [
                        InlineTextField(
                          label: 'العمر من',
                          icon: Icons.cake_outlined,
                          value: _ageMin?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          onSave: (v) async {
                            final parsed = int.tryParse(v.trim());
                            final ok = await _saveField({
                              'preferences': {'ageMin': parsed},
                            });
                            if (ok) setState(() => _ageMin = parsed);
                            return ok;
                          },
                        ),
                        InlineTextField(
                          label: 'العمر إلى',
                          icon: Icons.cake_outlined,
                          value: _ageMax?.toString() ?? '',
                          keyboardType: TextInputType.number,
                          onSave: (v) async {
                            final parsed = int.tryParse(v.trim());
                            final ok = await _saveField({
                              'preferences': {'ageMax': parsed},
                            });
                            if (ok) setState(() => _ageMax = parsed);
                            return ok;
                          },
                        ),
                        InlineDropdownField(
                          label: 'الولاية المفضلة',
                          icon: Icons.map_outlined,
                          value: _cities.contains(_prefCity) ? _prefCity : null,
                          options: _cities,
                          onSave: (v) async {
                            final ok = await _saveField({
                              'preferences': {'city': v},
                            });
                            if (ok) setState(() => _prefCity = v);
                            return ok;
                          },
                        ),
                      ],
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ],
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
// (تم حذف فرع الورق الزخرفي القديم من هنا — تصميم مسطّح حديث بلا
// عناصر clip-art، بنفس روح باقي شاشات التطبيق)
// ================================================================

// ================================================================
// ✅ رأس الصفحة — نسخة مبسطة واحترافية:
// عنوان + وصف قصير، بعدها أفاتار نظيف بحلقة مينت خفيفة + badge
// دائري صغير (كاميرا) فالزاوية السفلى لتبديل الأفاتار، بنفس هوية
// الألوان ديال الفورم (أخضر غامق + أبيض). بلا أي زخرفة إضافية
// (فروع ورق / لمعات) باش يبقى الهيدر بسيط ونظيف.
// ================================================================
class _EditHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onTapAvatar;
  final Widget avatarChild;
  final String name;

  const _EditHeader({
    required this.onBack,
    required this.onTapAvatar,
    required this.avatarChild,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kGold.withValues(alpha: 0.10), kBg],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back,
                  color: kDarkGreen,
                  textDirection: TextDirection.ltr,
                ),
              ),
              const Expanded(
                child: Text(
                  'تعديل الملف الشخصي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: kDarkGreen,
                    fontSize: 19,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'قم بتحديث معلوماتك الشخصية',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: 116,
            height: 116,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  padding: const EdgeInsets.all(3.2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [kGold, kMidGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: ClipOval(
                      child: Container(
                        color: kDarkGreen.withValues(alpha: 0.08),
                        child: avatarChild,
                      ),
                    ),
                  ),
                ),
                // ✅ badge دائري احترافي لتبديل الأفاتار — بنفس هوية
                // الألوان ديال الفورم (أخضر غامق + حلقة بيضاء)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: kDarkGreen,
                    shape: const CircleBorder(
                      side: BorderSide(color: Colors.white, width: 2.5),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTapAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [kDarkGreen, kGold],
            ).createShader(rect),
            child: Text(
              name.isEmpty ? '—' : name,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// بطاقة عامة (Container أبيض بعنوان + أيقونة فـ دائرة خفيفة + فرع ورق
// زخرفي بارز من الزاوية العلوية اليمنى)
// ================================================================
class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  const _Card({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.03)),
        boxShadow: [
          BoxShadow(
            color: kDarkGreen.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [kGold.withValues(alpha: 0.22), kDarkGreen.withValues(alpha: 0.08)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: kDarkGreen),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: kDarkGreen,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }
}

// ================================================================
// ✅ زر ✏️ صغير يوضع بجانب صندوق القيمة (مو فوق التسمية)
// ================================================================
class _EditPencilButton extends StatelessWidget {
  final VoidCallback onTap;
  const _EditPencilButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.edit_outlined, size: 16, color: kGold),
        ),
      ),
    );
  }
}

// ================================================================
// صندوق عرض القيمة (أيقونة فـ دائرة بيضاء + النص) — خلفية مينت خفيفة
// بلا حدود، نفس شكل الصورة المرجعية
// ================================================================
class _ValueBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPlaceholder;
  const _ValueBox({
    required this.icon,
    required this.text,
    this.isPlaceholder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: kMint.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 15, color: kDarkGreen),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: isPlaceholder ? Colors.grey.shade500 : Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// حقل نص قابل للتعديل inline: تسمية فوق، ثم صف [✏️] + [صندوق القيمة]
// →  عند التعديل: TextField + ✅ ❌
// ================================================================
class InlineTextField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String value;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final Future<bool> Function(String newValue) onSave;

  const InlineTextField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.onSave,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
  });

  @override
  State<InlineTextField> createState() => _InlineTextFieldState();
}

class _InlineTextFieldState extends State<InlineTextField> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant InlineTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_editing && oldWidget.value != widget.value) {
      _controller.text = widget.value;
    }
  }

  void _startEdit() {
    _controller.text = widget.value;
    setState(() => _editing = true);
  }

  void _cancel() {
    _controller.text = widget.value;
    setState(() => _editing = false);
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    final ok = await widget.onSave(_controller.text.trim());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kDarkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (!_editing)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditPencilButton(onTap: _startEdit),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ValueBox(
                      icon: widget.icon,
                      text: widget.value.isEmpty ? '—' : widget.value,
                      isPlaceholder: widget.value.isEmpty,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kDarkGreen,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: kDarkGreen,
                      size: 22,
                    ),
                    onPressed: _confirm,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: _cancel,
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    textAlign: TextAlign.right,
                    maxLines: widget.maxLines,
                    maxLength: widget.maxLength,
                    keyboardType: widget.keyboardType,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        widget.icon,
                        color: kDarkGreen,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: kDarkGreen,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ================================================================
// حقل Dropdown قابل للتعديل inline — نفس شكل [✏️] + [صندوق القيمة]
// ================================================================
class InlineDropdownField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String? value;
  final List<String> options;
  final Future<bool> Function(String newValue) onSave;

  const InlineDropdownField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.options,
    required this.onSave,
  });

  @override
  State<InlineDropdownField> createState() => _InlineDropdownFieldState();
}

class _InlineDropdownFieldState extends State<InlineDropdownField> {
  bool _editing = false;
  bool _saving = false;
  String? _pending;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kDarkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (!_editing)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditPencilButton(
                    onTap: () => setState(() {
                      _pending = widget.value;
                      _editing = true;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ValueBox(
                      icon: widget.icon,
                      text: widget.value ?? '—',
                      isPlaceholder: widget.value == null,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kDarkGreen,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: kDarkGreen,
                      size: 22,
                    ),
                    onPressed: _pending == null
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            final ok = await widget.onSave(_pending!);
                            if (!mounted) return;
                            setState(() {
                              _saving = false;
                              if (ok) _editing = false;
                            });
                          },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _editing = false),
                  ),
                ],
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _pending,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: kDarkGreen,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        widget.icon,
                        color: kDarkGreen,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    items: widget.options
                        .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                        .toList(),
                    onChanged: (v) => setState(() => _pending = v),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ================================================================
// حقل تاريخ الميلاد قابل للتعديل inline — نفس شكل [✏️] + [صندوق القيمة]
// ================================================================
class InlineDateField extends StatefulWidget {
  final String label;
  final DateTime? value;
  final Future<bool> Function(DateTime newValue) onSave;

  const InlineDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onSave,
  });

  @override
  State<InlineDateField> createState() => _InlineDateFieldState();
}

class _InlineDateFieldState extends State<InlineDateField> {
  bool _editing = false;
  bool _saving = false;
  DateTime? _pending;

  String _fmt(DateTime? d) => d == null
      ? '—'
      : '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pending ?? widget.value ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: kDarkGreen,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _pending = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.label,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: kDarkGreen,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (!_editing)
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _EditPencilButton(
                    onTap: () => setState(() {
                      _pending = widget.value;
                      _editing = true;
                    }),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ValueBox(
                      icon: Icons.calendar_today_outlined,
                      text: _fmt(widget.value),
                      isPlaceholder: widget.value == null,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kDarkGreen,
                      ),
                    ),
                  )
                else ...[
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: kDarkGreen,
                      size: 22,
                    ),
                    onPressed: _pending == null
                        ? null
                        : () async {
                            setState(() => _saving = true);
                            final ok = await widget.onSave(_pending!);
                            if (!mounted) return;
                            setState(() {
                              _saving = false;
                              if (ok) _editing = false;
                            });
                          },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.cancel_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                    onPressed: () => setState(() => _editing = false),
                  ),
                ],
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: kDarkGreen,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _fmt(_pending),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}