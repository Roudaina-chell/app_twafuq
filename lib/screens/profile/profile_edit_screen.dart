// screens/profile/profile_edit_screen.dart
//
// نسخة بالتعديل الـ inline: كل حقل فيه ✏️ بروحو، كي تدوسي عليه
// الحقل يتبدل لـ TextField/Dropdown/Date قابل للتعديل فـ نفس المكان،
// مع ✅ (حفظ هاذاك الحقل وحدو فـ Firestore) و ❌ (إلغاء ورجوع للقيمة القديمة).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'avatar_selection.dart';

const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
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
        _avatarAsset = data['avatarAsset'] as String?;
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: kDarkGreen,
                      size: 20,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'تعديل الملف الشخصي',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kDarkGreen,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),

              // الأفاتار (عندها تعديل خاص بيها أصلا: الضغط عليها)
              Center(
                child: GestureDetector(
                  onTap: _changeAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kGold, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: kGold.withValues(alpha: 0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: ClipOval(
                            child: Container(
                              color: kDarkGreen.withValues(alpha: 0.08),
                              child:
                                  (_avatarAsset == null ||
                                      _avatarAsset!.isEmpty)
                                  ? const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: kDarkGreen,
                                    )
                                  : Image.asset(
                                      _avatarAsset!,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter,
                                      errorBuilder: (context, error, stack) =>
                                          const Icon(
                                            Icons.person,
                                            size: 56,
                                            color: kDarkGreen,
                                          ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kDarkGreen,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'اضغط على الصورة لتغييرها',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ),
              const SizedBox(height: 24),

              // بطاقة المعلومات الأساسية
              _Card(
                title: 'المعلومات الأساسية',
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
                    icon: Icons.location_city_outlined,
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

              const SizedBox(height: 20),

              // بطاقة التفضيلات
              _Card(
                title: 'تفضيلات البحث',
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// بطاقة عامة (Container أبيض بعنوان)
// ================================================================
class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.badge_outlined, size: 16, color: kGold),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
// حقل نص قابل للتعديل inline: عرض عادي + ✏️  →  TextField + ✅ ❌
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
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kDarkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: kGold),
                  onPressed: _startEdit,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (!_editing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.value.isEmpty ? '—' : widget.value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: widget.value.isEmpty
                      ? Colors.grey.shade400
                      : Colors.black87,
                  fontSize: 14,
                ),
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
// حقل Dropdown قابل للتعديل inline
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
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kDarkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: kGold),
                  onPressed: () => setState(() {
                    _pending = widget.value;
                    _editing = true;
                  }),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (!_editing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                widget.value ?? '—',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: widget.value == null
                      ? Colors.grey.shade400
                      : Colors.black87,
                  fontSize: 14,
                ),
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
// حقل تاريخ الميلاد قابل للتعديل inline
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
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: kDarkGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_editing)
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: kGold),
                  onPressed: () => setState(() {
                    _pending = widget.value;
                    _editing = true;
                  }),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (!_editing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(
                _fmt(widget.value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: widget.value == null
                      ? Colors.grey.shade400
                      : Colors.black87,
                  fontSize: 14,
                ),
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
