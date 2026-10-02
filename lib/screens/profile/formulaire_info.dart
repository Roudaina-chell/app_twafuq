// screens/profile/formulaire_info.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'avatar_selection.dart';

class FormulaireInfo extends StatefulWidget {
  const FormulaireInfo({super.key});

  @override
  State<FormulaireInfo> createState() => _FormulaireInfoState();
}

class _FormulaireInfoState extends State<FormulaireInfo>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();
  final _birthDateController = TextEditingController();

  DateTime? _birthDate;
  String? _educationLevel;
  String? _city;
  String? _maritalStatus;

  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _educationLevels = [
    'ثانوية',
    'إجازة (ليسانس)',
    'ماجستير',
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

  final List<String> _maritalStatuses = ['أعزب', 'مطلّق', 'أرمل'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _occupationController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')} / ${d.month.toString().padLeft(2, '0')} / ${d.year}';

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final p = _Pal.of(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme:
                (p.isDark
                        ? const ColorScheme.dark()
                        : const ColorScheme.light())
                    .copyWith(
                      primary: p.primary,
                      onPrimary: p.onPrimary,
                      surface: p.card,
                      onSurface: p.isDark ? Colors.white : Colors.black87,
                    ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _birthDate == null ||
        _educationLevel == null ||
        _occupationController.text.trim().isEmpty ||
        _city == null ||
        _maritalStatus == null) {
      setState(() {
        _errorMessage = 'يُرجى تعبئة جميع الحقول قبل المتابعة';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: لا يوجد مستخدم مسجّل الدخول حاليًا';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fullName': _nameController.text.trim(),
        'birthDate': _birthDate!.toIso8601String(),
        'educationLevel': _educationLevel,
        'occupation': _occupationController.text.trim(),
        'city': _city,
        'maritalStatus': _maritalStatus,
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع، يُرجى إعادة المحاولة';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _buildDecoration({
    required _Pal p,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: p.muted, fontSize: 13.5),
      prefixIcon: Icon(icon, color: p.primary, size: 19),
      suffixIcon: suffix,
      filled: true,
      fillColor: p.field,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDE3B40), width: 1.4),
      ),
    );
  }

  Widget _buildLabel(_Pal p, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            text,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: p.primary,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionDivider(_Pal p, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 6),
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: p.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: TextStyle(
                color: p.gold,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: p.border)),
        ],
      ),
    );
  }

  Widget _dropdown({
    required _Pal p,
    required String? value,
    required String hint,
    required String decoHint,
    required IconData icon,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: p.card,
      hint: Text(hint, style: TextStyle(color: p.muted, fontSize: 13.5)),
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: p.primary),
      decoration: _buildDecoration(p: p, hint: decoHint, icon: icon),
      items: items
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: const TextStyle(fontSize: 13.5)),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _Pal.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ===== الترويسة وشريط التقدم =====
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: p.card,
                          shape: BoxShape.circle,
                          boxShadow: p.isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.10),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: p.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'TAWAFUQ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: p.primary,
                          letterSpacing: 1.8,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.4,
                            minHeight: 7,
                            backgroundColor: p.track,
                            valueColor: AlwaysStoppedAnimation<Color>(p.gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: p.gold,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: p.gold.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          '٢ / ٥',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  // ===== أيقونة القسم =====
                  Center(
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            p.gold.withValues(alpha: 0.16),
                            p.gold.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: p.gold.withValues(alpha: 0.35),
                          width: 1.6,
                        ),
                      ),
                      child: Icon(
                        Icons.person_outline_rounded,
                        color: p.primary,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ===== العنوان والوصف =====
                  Text(
                    'معلومات أساسية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'نحتاج إلى بعض المعلومات لإنشاء ملفك الشخصي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: p.subtitle,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // ===== بطاقة الحقول =====
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    decoration: BoxDecoration(
                      color: p.card,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: p.border),
                      boxShadow: p.shadow(alpha: 0.06, blur: 24, dy: 10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSectionDivider(p, 'البيانات الشخصية'),

                        _buildLabel(p, 'الاسم الكامل'),
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          decoration: _buildDecoration(
                            p: p,
                            hint: 'أدخل اسمك الكامل',
                            icon: Icons.person_outline_rounded,
                          ),
                        ),

                        _buildLabel(p, 'تاريخ الميلاد'),
                        GestureDetector(
                          onTap: _pickBirthDate,
                          child: AbsorbPointer(
                            child: TextField(
                              textAlign: TextAlign.right,
                              controller: _birthDateController,
                              decoration: _buildDecoration(
                                p: p,
                                hint: 'اختر تاريخ ميلادك',
                                icon: Icons.calendar_today_outlined,
                                suffix: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),

                        _buildSectionDivider(p, 'المسار المهني والتعليمي'),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildLabel(p, 'المهنة'),
                                  TextField(
                                    controller: _occupationController,
                                    textAlign: TextAlign.right,
                                    decoration: _buildDecoration(
                                      p: p,
                                      hint: 'مهنتك',
                                      icon: Icons.work_outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildLabel(p, 'المستوى التعليمي'),
                                  _dropdown(
                                    p: p,
                                    value: _educationLevel,
                                    hint: 'اختر',
                                    decoHint: 'المستوى',
                                    icon: Icons.school_outlined,
                                    items: _educationLevels,
                                    onChanged: (v) =>
                                        setState(() => _educationLevel = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        _buildSectionDivider(p, 'بيانات إضافية'),

                        _buildLabel(p, 'المدينة'),
                        _dropdown(
                          p: p,
                          value: _city,
                          hint: 'اختر مدينتك',
                          decoHint: 'المدينة',
                          icon: Icons.location_city_outlined,
                          items: _cities,
                          onChanged: (v) => setState(() => _city = v),
                        ),

                        _buildLabel(p, 'الحالة الاجتماعية'),
                        _dropdown(
                          p: p,
                          value: _maritalStatus,
                          hint: 'اختر حالتك الاجتماعية',
                          decoHint: 'الحالة الاجتماعية',
                          icon: Icons.people_outline,
                          items: _maritalStatuses,
                          onChanged: (v) => setState(() => _maritalStatus = v),
                        ),
                      ],
                    ),
                  ),

                  // ===== رسالة الخطأ =====
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDE3B40).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFFDE3B40).withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFDE3B40),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                color: Color(0xFFDE3B40),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ===== زر المتابعة =====
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Material(
                      color: p.primary,
                      borderRadius: BorderRadius.circular(18),
                      elevation: 0,
                      child: InkWell(
                        onTap: _isLoading ? null : _submit,
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: p.shadow(alpha: 0.25, blur: 14, dy: 6),
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: p.onPrimary,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'متابعة',
                                        style: TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w700,
                                          color: p.onPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_back_ios_new_rounded,
                                        size: 14,
                                        color: p.onPrimary,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== ملاحظة الخصوصية =====
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, size: 14, color: p.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'جميع بياناتك محمية ولا تظهر لأي مستخدم آخر',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: p.subtitle, fontSize: 12),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
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
  final Color onPrimary;
  final Color bg;
  final Color card;
  final Color border;
  final Color field;
  final Color track;
  final Color subtitle;
  final Color muted;
  final Color gold;

  const _Pal._({
    required this.isDark,
    required this.primary,
    required this.onPrimary,
    required this.bg,
    required this.card,
    required this.border,
    required this.field,
    required this.track,
    required this.subtitle,
    required this.muted,
    required this.gold,
  });

  factory _Pal.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    return _Pal._(
      isDark: isDark,
      primary: primary,
      onPrimary: theme.colorScheme.onPrimary,
      bg: theme.scaffoldBackgroundColor,
      card: theme.colorScheme.surface,
      border: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFEFEAE2),
      field: isDark
          ? const Color(0xFF1C2A24)
          : const Color(0xFFFAF7F2).withValues(alpha: 0.6),
      track: isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.grey.shade200,
      subtitle: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
      muted: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
      gold: const Color(0xFFC9A24B),
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