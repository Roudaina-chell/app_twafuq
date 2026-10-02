// screens/profile/personal_info_edit_screen.dart
//
// شاشة "تعديل الملف الشخصي".
// كل حقل قابل للتعديل مباشرة بالضغط عليه (بدون أيقونات قلم):
// - الاسم، المهنة، النبذة، العمر: حقل نصي يأخذ التركيز مباشرة.
// - تاريخ الميلاد: يفتح منتقي التاريخ.
// - المستوى التعليمي، المدينة، الحالة العائلية، الولاية المفضلة:
//   قائمة اختيار سفلية.
// زر "حفظ التغييرات" يحفظ كل شيء دفعة واحدة. الصورة الرمزية تُحفظ فورًا.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'avatar_picker_screen.dart';

// الألوان الأصلية (نخليوها باش أي ملف آخر يستعملها ما يتكسرش)
const Color kDarkGreen = Color(0xFF0F3D2E);
const Color kMidGreen = Color(0xFF1A6B4A);
const Color kGold = Color(0xFFC9A24B);
const Color kBg = Color(0xFFFAF7F2);
const Color kMint = Color(0xFFE9F3EC);
const Color kFieldFill = Color(0xFFF6F8F5);
const Color kFieldBorder = Color(0xFFE2E7E1);

// لون الكتابة في المظهر الليلي (كريمي ذهبي بدل الأبيض)
const Color kDarkText = Color(0xFFE6D5A8);

// ------------------------------------------------------------
// لوحة الألوان: تتبدل تلقائياً حسب المظهر (نهاري / ليلي)
// ------------------------------------------------------------
class _P {
  final bool isDark;
  final Color bg; // خلفية الصفحة (أعلى)
  final Color bgEnd; // خلفية الصفحة (أسفل)
  final Color card; // البطاقات
  final Color sheet; // الـ bottom sheet
  final Color fieldFill; // خلفية الحقول
  final Color fieldBorder; // حدود الحقول
  final Color title; // العناوين والـ labels والاسم (ذهبي في الليلي)
  final Color text; // قيم الحقول والنصوص العادية
  final Color icon; // الأيقونات
  final Color mint; // زر الرجوع
  final Color hint; // النص الباهت
  final Color subtitle; // النص الثانوي
  final Color handle; // مقبض الـ sheet
  final Color avatarRing; // إطار الأفاتار
  final Color avatarInner; // داخل الأفاتار
  final Color saveBtn; // زر الحفظ
  final Color shadow;
  final Color error;

  const _P({
    required this.isDark,
    required this.bg,
    required this.bgEnd,
    required this.card,
    required this.sheet,
    required this.fieldFill,
    required this.fieldBorder,
    required this.title,
    required this.text,
    required this.icon,
    required this.mint,
    required this.hint,
    required this.subtitle,
    required this.handle,
    required this.avatarRing,
    required this.avatarInner,
    required this.saveBtn,
    required this.shadow,
    required this.error,
  });

  static const _P light = _P(
    isDark: false,
    bg: kBg,
    bgEnd: Color(0xFFEEF4EE),
    card: Colors.white,
    sheet: Colors.white,
    fieldFill: Color(0xFFFAFAFA),
    fieldBorder: Color(0xFFEEEEEE),
    title: kDarkGreen,
    text: kDarkGreen,
    icon: kDarkGreen,
    mint: kMint,
    hint: Color(0xFFBDBDBD),
    subtitle: Color(0xFF9E9E9E),
    handle: Color(0xFFE0E0E0),
    avatarRing: Color(0xFF8FA595),
    avatarInner: Colors.white,
    saveBtn: kDarkGreen,
    shadow: Color(0x14000000),
    error: Colors.red,
  );

  static const _P dark = _P(
    isDark: true,
    bg: Color(0xFF0E1512),
    bgEnd: Color(0xFF121C17),
    card: Color(0xFF17221D),
    sheet: Color(0xFF17221D),
    fieldFill: Color(0xFF1D2B25),
    fieldBorder: Color(0xFF2A3A33),
    title: kGold,
    text: kDarkText, // <-- كان أبيض، وليا كريمي ذهبي
    icon: kGold,
    mint: Color(0xFF26261A),
    hint: Color(0xFF6F8078),
    subtitle: Color(0xFF8FA198),
    handle: Color(0xFF3A4A43),
    avatarRing: kGold,
    avatarInner: Color(0xFF17221D),
    saveBtn: kMidGreen,
    shadow: Color(0x66000000),
    error: Color(0xFFFF8A80),
  );

  static _P of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

class PersonalInfoEditScreen extends StatefulWidget {
  const PersonalInfoEditScreen({super.key});

  @override
  State<PersonalInfoEditScreen> createState() => _PersonalInfoEditScreenState();
}

class _PersonalInfoEditScreenState extends State<PersonalInfoEditScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // الحقول النصية
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _bioController = TextEditingController();
  final _ageMinController = TextEditingController();
  final _ageMaxController = TextEditingController();

  final _nameFocus = FocusNode();
  final _occupationFocus = FocusNode();
  final _bioFocus = FocusNode();
  final _ageMinFocus = FocusNode();
  final _ageMaxFocus = FocusNode();

  // الحقول الأخرى
  String _displayName = '';
  DateTime? _birthDate;
  String? _educationLevel;
  String? _city;
  String? _maritalStatus;
  String? _avatarAsset;
  String _gender = 'female';
  String? _prefCity;

  final List<String> _educationLevels = const [
    'ثانوي',
    'ليسانس',
    'ماستر',
    'دكتوراه',
    'أخرى',
  ];
  final List<String> _cities = const [
    'الجزائر العاصمة',
    'وهران',
    'قسنطينة',
    'قالمة',
    'عنابة',
    'البليدة',
    'أخرى',
  ];
  final List<String> _maritalStatuses = const ['أعزب', 'مطلق', 'أرمل'];

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  _P get _p => _P.of(context);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occupationController.dispose();
    _bioController.dispose();
    _ageMinController.dispose();
    _ageMaxController.dispose();
    _nameFocus.dispose();
    _occupationFocus.dispose();
    _bioFocus.dispose();
    _ageMinFocus.dispose();
    _ageMaxFocus.dispose();
    super.dispose();
  }

  int? _toInt(dynamic v) {
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> _loadProfile() async {
    try {
      if (_uid.isEmpty) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'لا يوجد مستخدم مسجّل الدخول';
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

      if (!mounted) return;
      setState(() {
        _displayName =
            (data['fullName'] as String?) ?? (data['name'] as String?) ?? '';
        _nameController.text = _displayName;
        _occupationController.text =
            (data['occupation'] as String?) ?? (data['job'] as String?) ?? '';
        _bioController.text =
            (data['bio'] as String?) ?? (data['about'] as String?) ?? '';
        _birthDate = (rawBirth != null && rawBirth.isNotEmpty)
            ? DateTime.tryParse(rawBirth)
            : null;
        _educationLevel = data['educationLevel'] as String?;
        _city = data['city'] as String?;
        _maritalStatus = data['maritalStatus'] as String?;
        _avatarAsset =
            (data['avatarAsset'] as String?) ?? (data['avatarPath'] as String?);
        _gender = (data['gender'] as String?)?.toLowerCase() == 'male'
            ? 'male'
            : 'female';
        _ageMinController.text =
            _toInt(preferences['ageMin'])?.toString() ?? '';
        _ageMaxController.text =
            _toInt(preferences['ageMax'])?.toString() ?? '';
        final pc =
            (preferences['city'] as String?) ??
            (preferences['wilaya'] as String?);
        _prefCity = _cities.contains(pc) ? pc : null;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('PersonalInfoEditScreen._loadProfile error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل المعلومات';
        _isLoading = false;
      });
    }
  }

  int _computeAge(DateTime birth) {
    final now = DateTime.now();
    int age = now.year - birth.year;
    final hadBirthday =
        now.month > birth.month ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) age--;
    return age;
  }

  String _formatDate(DateTime d) =>
      '${d.year} / ${d.month.toString().padLeft(2, '0')} / ${d.day.toString().padLeft(2, '0')}';

  Future<bool> _saveField(Map<String, dynamic> payload) async {
    try {
      if (_uid.isEmpty) return false;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .set(payload, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('PersonalInfoEditScreen._saveField error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء الحفظ، حاول مرة أخرى')),
        );
      }
      return false;
    }
  }

  Future<void> _changeAvatar() async {
    FocusScope.of(context).unfocus();
    final selected = await showAvatarPicker(
      context,
      gender: _gender,
      currentAvatarPath: _avatarAsset,
    );
    if (!mounted || selected == null || selected == _avatarAsset) return;
    final ok = await _saveField({'avatarAsset': selected});
    if (ok && mounted) setState(() => _avatarAsset = selected);
  }

  // ------------------------------------------------------------
  // الاختيارات
  // ------------------------------------------------------------
  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final p = _p;
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: p.isDark
              ? ColorScheme.dark(
                  primary: p.icon,
                  onPrimary: const Color(0xFF0E1512),
                  surface: p.card,
                  onSurface: p.text,
                )
              : const ColorScheme.light(
                  primary: kDarkGreen,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black87,
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _birthDate = picked);
  }

  Future<void> _selectFromList({
    required String title,
    required List<String> options,
    required String? current,
    required ValueChanged<String> onSelected,
  }) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _p.sheet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final p = _P.of(ctx);
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.handle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: p.title,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: options.map((o) {
                        final isSelected = o == current;
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          title: Text(
                            o,
                            style: TextStyle(
                              color: isSelected ? p.title : p.text,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(Icons.check_circle_rounded, color: p.icon)
                              : null,
                          onTap: () => Navigator.pop(ctx, o),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (selected != null && mounted) onSelected(selected);
  }

  // ------------------------------------------------------------
  // الحفظ
  // ------------------------------------------------------------
  String? _validate() {
    if (_nameController.text.trim().isEmpty) return 'أدخل اسمك الكامل';
    if (_birthDate == null) return 'اختر تاريخ ميلادك';
    if (_occupationController.text.trim().isEmpty) return 'أدخل مهنتك';
    if (_educationLevel == null) return 'اختر مستواك التعليمي';
    if (_city == null) return 'اختر مدينتك';
    if (_maritalStatus == null) return 'اختر حالتك العائلية';

    if (_gender == 'male') {
      final min = int.tryParse(_ageMinController.text.trim());
      final max = int.tryParse(_ageMaxController.text.trim());
      if (min != null && min < 18) return 'الحد الأدنى للعمر هو 18 سنة';
      if (min != null && max != null && min > max) {
        return 'العمر الأدنى يجب ألا يتجاوز العمر الأقصى';
      }
    }
    return null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final error = _validate();
    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final name = _nameController.text.trim();
    final payload = <String, dynamic>{
      'fullName': name,
      'birthDate': _birthDate!.toIso8601String(),
      'age': _computeAge(_birthDate!),
      'occupation': _occupationController.text.trim(),
      'educationLevel': _educationLevel,
      'city': _city,
      'maritalStatus': _maritalStatus,
      'bio': _bioController.text.trim(),
    };

    if (_gender == 'male') {
      payload['preferences'] = {
        'ageMin': int.tryParse(_ageMinController.text.trim()),
        'ageMax': int.tryParse(_ageMaxController.text.trim()),
        'city': _prefCity,
      };
    }

    final ok = await _saveField(payload);
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (ok) _displayName = name;
    });

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ التغييرات بنجاح')));
    }
  }

  static Widget _buildAvatarImage({
    required String? source,
    required Color iconColor,
  }) {
    final fallback = Icon(Icons.person, size: 56, color: iconColor);
    if (source == null || source.trim().isEmpty) return fallback;
    final isNetwork =
        source.startsWith('http://') || source.startsWith('https://');
    return isNetwork
        ? Image.network(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) => fallback,
          )
        : Image.asset(
            source,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stack) => fallback,
          );
  }

  // ------------------------------------------------------------
  // الواجهة
  // ------------------------------------------------------------
  TextStyle get _valueStyle =>
      TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _p.text);

  TextStyle get _hintStyle => TextStyle(fontSize: 14, color: _p.hint);

  InputDecoration _plainDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: _hintStyle,
    border: InputBorder.none,
    isDense: true,
    counterStyle: TextStyle(color: _p.subtitle),
    contentPadding: const EdgeInsets.symmetric(vertical: 12),
  );

  Widget _selectText(String? value, String hint) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(value ?? hint, style: value == null ? _hintStyle : _valueStyle),
  );

  @override
  Widget build(BuildContext context) {
    final p = _p;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Center(child: CircularProgressIndicator(color: p.icon)),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: p.bg,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.bg, p.bgEnd],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EditHeader(
                      onBack: () => Navigator.maybePop(context),
                      onTapAvatar: _changeAvatar,
                      avatarChild: _buildAvatarImage(
                        source: _avatarAsset,
                        iconColor: p.icon,
                      ),
                      name: _displayName,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FormCard(
                            title: 'المعلومات الأساسية',
                            icon: Icons.badge_outlined,
                            children: [
                              // الاسم الكامل
                              _FieldCard(
                                label: 'الاسم الكامل',
                                icon: Icons.person_outline_rounded,
                                onTap: () => _nameFocus.requestFocus(),
                                child: TextField(
                                  controller: _nameController,
                                  focusNode: _nameFocus,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: p.icon,
                                  style: _valueStyle,
                                  decoration: _plainDecoration(
                                    'أدخل اسمك الكامل',
                                  ),
                                ),
                              ),

                              // تاريخ الميلاد
                              _FieldCard(
                                label: 'تاريخ الميلاد',
                                icon: Icons.calendar_today_outlined,
                                onTap: _pickBirthDate,
                                child: _selectText(
                                  _birthDate == null
                                      ? null
                                      : _formatDate(_birthDate!),
                                  'اختر تاريخ ميلادك',
                                ),
                              ),

                              // المهنة
                              _FieldCard(
                                label: 'المهنة',
                                icon: Icons.work_outline,
                                onTap: () => _occupationFocus.requestFocus(),
                                child: TextField(
                                  controller: _occupationController,
                                  focusNode: _occupationFocus,
                                  textInputAction: TextInputAction.next,
                                  cursorColor: p.icon,
                                  style: _valueStyle,
                                  decoration: _plainDecoration('أدخل مهنتك'),
                                ),
                              ),

                              // المستوى التعليمي
                              _FieldCard(
                                label: 'المستوى التعليمي',
                                icon: Icons.school_outlined,
                                onTap: () => _selectFromList(
                                  title: 'المستوى التعليمي',
                                  options: _educationLevels,
                                  current: _educationLevel,
                                  onSelected: (v) =>
                                      setState(() => _educationLevel = v),
                                ),
                                child: _selectText(
                                  _educationLevel,
                                  'اختر مستواك التعليمي',
                                ),
                              ),

                              // المدينة
                              _FieldCard(
                                label: 'المدينة',
                                icon: Icons.location_on_outlined,
                                onTap: () => _selectFromList(
                                  title: 'المدينة',
                                  options: _cities,
                                  current: _city,
                                  onSelected: (v) => setState(() => _city = v),
                                ),
                                child: _selectText(_city, 'اختر مدينتك'),
                              ),

                              // الحالة العائلية
                              _FieldCard(
                                label: 'الحالة العائلية',
                                icon: Icons.people_outline,
                                onTap: () => _selectFromList(
                                  title: 'الحالة العائلية',
                                  options: _maritalStatuses,
                                  current: _maritalStatus,
                                  onSelected: (v) =>
                                      setState(() => _maritalStatus = v),
                                ),
                                child: _selectText(
                                  _maritalStatus,
                                  'اختر حالتك العائلية',
                                ),
                              ),

                              // نبذة عني
                              _FieldCard(
                                label: 'نبذة عني',
                                icon: Icons.info_outline_rounded,
                                multiline: true,
                                onTap: () => _bioFocus.requestFocus(),
                                child: TextField(
                                  controller: _bioController,
                                  focusNode: _bioFocus,
                                  minLines: 2,
                                  maxLines: 4,
                                  maxLength: 300,
                                  cursorColor: p.icon,
                                  style: _valueStyle,
                                  decoration: _plainDecoration(
                                    'اكتب نبذة عن نفسك',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // تفضيلات البحث (للذكور فقط)
                          if (_gender == 'male') ...[
                            const SizedBox(height: 18),
                            _FormCard(
                              title: 'تفضيلات البحث',
                              icon: Icons.tune_rounded,
                              children: [
                                _FieldCard(
                                  label: 'العمر من',
                                  icon: Icons.cake_outlined,
                                  onTap: () => _ageMinFocus.requestFocus(),
                                  child: TextField(
                                    controller: _ageMinController,
                                    focusNode: _ageMinFocus,
                                    keyboardType: TextInputType.number,
                                    cursorColor: p.icon,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    style: _valueStyle,
                                    decoration: _plainDecoration('مثال: 22'),
                                  ),
                                ),
                                _FieldCard(
                                  label: 'العمر إلى',
                                  icon: Icons.cake_outlined,
                                  onTap: () => _ageMaxFocus.requestFocus(),
                                  child: TextField(
                                    controller: _ageMaxController,
                                    focusNode: _ageMaxFocus,
                                    keyboardType: TextInputType.number,
                                    cursorColor: p.icon,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(2),
                                    ],
                                    style: _valueStyle,
                                    decoration: _plainDecoration('مثال: 35'),
                                  ),
                                ),
                                _FieldCard(
                                  label: 'الولاية المفضلة',
                                  icon: Icons.map_outlined,
                                  onTap: () => _selectFromList(
                                    title: 'الولاية المفضلة',
                                    options: _cities,
                                    current: _prefCity,
                                    onSelected: (v) =>
                                        setState(() => _prefCity = v),
                                  ),
                                  child: _selectText(_prefCity, 'اختر ولاية'),
                                ),
                              ],
                            ),
                          ],

                          if (_errorMessage != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: p.error.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: p.error, fontSize: 13),
                              ),
                            ),
                          ],

                          const SizedBox(height: 22),
                          _SaveButton(isSaving: _isSaving, onPressed: _save),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// الهيدر: زر الرجوع على اليسار، العنوان في الوسط،
// والصورة الرمزية مع زر التعديل في الزاوية العليا.
// ============================================================
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
    final p = _P.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      child: Column(
        children: [
          Row(
            children: [
              // في RTL: الأول يظهر على اليمين، لذلك الفراغ أولًا
              const SizedBox(width: 44),
              Expanded(
                child: Text(
                  'تعديل الملف الشخصي',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.title,
                    fontSize: 19,
                  ),
                ),
              ),
              Material(
                color: p.mint,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.arrow_back,
                      color: p.icon,
                      size: 20,
                      textDirection: TextDirection.ltr,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'قم بتحديث معلوماتك الشخصية',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.subtitle),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 116,
            height: 108,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 100,
                    height: 100,
                    padding: const EdgeInsets.all(3.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: p.avatarRing, width: 2.6),
                      boxShadow: [
                        BoxShadow(
                          color: p.isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : kDarkGreen.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: p.avatarInner,
                      ),
                      child: ClipOval(
                        child: Container(
                          color: p.icon.withValues(alpha: 0.08),
                          child: avatarChild,
                        ),
                      ),
                    ),
                  ),
                ),
                // زر القلم: تحت الأفاتار جهة اليمين
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Material(
                    color: p.saveBtn,
                    shape: CircleBorder(
                      side: BorderSide(color: p.avatarInner, width: 2.5),
                    ),
                    elevation: 2,
                    shadowColor: Colors.black26,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onTapAvatar,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.edit_rounded,
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
          const SizedBox(height: 8),
          Text(
            name.isEmpty ? '—' : name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: p.title,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// بطاقة واحدة تجمع الحقول (نفس أسلوب formulaire_info)
class _FormCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: p.isDark ? Border.all(color: p.fieldBorder) : null,
        boxShadow: [
          BoxShadow(
            color: p.shadow,
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
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: p.icon.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: p.icon),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.5,
                  color: p.title,
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

// ============================================================
// حقل: عنوان + صندوق بنفس تصميم formulaire_info
// (خلفية رمادية فاتحة، حدود رفيعة، أيقونة خضراء داكنة).
// الحقل كله قابل للضغط عبر [onTap].
// ============================================================
class _FieldCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;
  final bool multiline;

  const _FieldCard({
    required this.label,
    required this.icon,
    required this.child,
    this.onTap,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    final radius = BorderRadius.circular(14);

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: TextStyle(
                color: p.title,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: p.fieldFill,
            borderRadius: radius,
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Container(
                constraints: const BoxConstraints(minHeight: 52),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: Border.all(color: p.fieldBorder),
                ),
                child: Row(
                  crossAxisAlignment: multiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: multiline ? 14 : 0),
                      child: Icon(icon, color: p.icon, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: child),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final bool isSaving;
  final VoidCallback onPressed;

  const _SaveButton({required this.isSaving, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final p = _P.of(context);
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.72,
        height: 54,
        child: ElevatedButton(
          onPressed: isSaving ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: p.saveBtn,
            disabledBackgroundColor: p.saveBtn.withValues(alpha: 0.6),
            elevation: p.isDark ? 0 : 4,
            shadowColor: kDarkGreen.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'حفظ التغييرات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
