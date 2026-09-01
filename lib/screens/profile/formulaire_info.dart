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
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();

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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: darkGreen,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
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
        _errorMessage = 'خاصك تعمري جميع الحقول';
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
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
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
        _errorMessage = 'وقع خطأ، عاودي المحاولة';
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
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: Icon(icon, color: darkGreen, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: darkGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: darkGreen,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
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
                  // HEADER مع شريط التقدم
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: darkGreen, size: 20),
                      ),
                      const Text(
                        'TAWAFUQ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          letterSpacing: 1.5,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 0.4,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(gold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: gold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '2/5',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // أيقونة كبيرة
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            darkGreen.withValues(alpha: 0.08),
                            gold.withValues(alpha: 0.12),
                          ],
                        ),
                        border: Border.all(color: gold.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: darkGreen,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // العنوان والوصف
                  const Text(
                    'معلومات أساسية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'نحتاج بعض المعلومات لبناء ملفك الشخصي',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // بطاقة الحقول
                  Container(
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
                        // الاسم الكامل
                        _buildLabel('الاسم الكامل'),
                        TextField(
                          controller: _nameController,
                          textAlign: TextAlign.right,
                          decoration: _buildDecoration(
                            hint: 'أدخل اسمك الكامل',
                            icon: Icons.person_outline_rounded,
                          ),
                        ),

                        // تاريخ الميلاد
                        _buildLabel('تاريخ الميلاد'),
                        GestureDetector(
                          onTap: _pickBirthDate,
                          child: AbsorbPointer(
                            child: TextField(
                              textAlign: TextAlign.right,
                              controller: TextEditingController(
                                text: _birthDate == null
                                    ? ''
                                    : '${_birthDate!.day.toString().padLeft(2, '0')} / ${_birthDate!.month.toString().padLeft(2, '0')} / ${_birthDate!.year}',
                              ),
                              decoration: _buildDecoration(
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

                        // المهنة والمستوى التعليمي
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  _buildLabel('المهنة'),
                                  TextField(
                                    controller: _occupationController,
                                    textAlign: TextAlign.right,
                                    decoration: _buildDecoration(
                                      hint: 'المهنة',
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
                                  _buildLabel('المستوى التعليمي'),
                                  DropdownButtonFormField<String>(
                                    value: _educationLevel,
                                    isExpanded: true,
                                    hint: Text(
                                      'اختر',
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: darkGreen,
                                    ),
                                    decoration: _buildDecoration(
                                      hint: 'المستوى',
                                      icon: Icons.school_outlined,
                                    ),
                                    items: _educationLevels.map((e) {
                                      return DropdownMenuItem(
                                        value: e,
                                        child: Text(e),
                                      );
                                    }).toList(),
                                    onChanged: (v) =>
                                        setState(() => _educationLevel = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // المدينة
                        _buildLabel('المدينة'),
                        DropdownButtonFormField<String>(
                          value: _city,
                          isExpanded: true,
                          hint: Text(
                            'اختر مدينتك',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: darkGreen,
                          ),
                          decoration: _buildDecoration(
                            hint: 'المدينة',
                            icon: Icons.location_city_outlined,
                          ),
                          items: _cities.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _city = v),
                        ),

                        // الحالة العائلية
                        _buildLabel('الحالة العائلية'),
                        DropdownButtonFormField<String>(
                          value: _maritalStatus,
                          isExpanded: true,
                          hint: Text(
                            'اختر حالتك العائلية',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: darkGreen,
                          ),
                          decoration: _buildDecoration(
                            hint: 'الحالة العائلية',
                            icon: Icons.people_outline,
                          ),
                          items: _maritalStatuses.map((m) {
                            return DropdownMenuItem(
                              value: m,
                              child: Text(m),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => _maritalStatus = v),
                        ),
                      ],
                    ),
                  ),

                  // عرض الخطأ
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

                  const SizedBox(height: 20),

                  // زر متابعة
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        elevation: 4,
                        shadowColor: darkGreen.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                              'متابعة',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ملاحظة الخصوصية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: darkGreen,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'جميع بياناتك محمية ولا تظهر للمستخدمين الآخرين',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}