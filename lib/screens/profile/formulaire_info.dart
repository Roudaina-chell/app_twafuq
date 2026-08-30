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

class _FormulaireInfoState extends State<FormulaireInfo> {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  final _nameController = TextEditingController();
  final _occupationController = TextEditingController();

  DateTime? _birthDate;
  String? _educationLevel;
  String? _city;
  String? _maritalStatus;

  bool _isLoading = false;
  String? _errorMessage;

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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18),
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

  InputDecoration _decoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      suffixIcon: Icon(icon, color: darkGreen, size: 20),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          text,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back, color: darkGreen),
                  ),
                  const Text(
                    'TAWAFUQ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(gold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: darkGreen.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: darkGreen,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'معلومات أساسية',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkGreen,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'نحتاج بعض المعلومات لبناء ملفك الشخصي',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              _label('الاسم الكامل'),
              TextField(
                controller: _nameController,
                textAlign: TextAlign.right,
                decoration: _decoration('الاسم الكامل', Icons.person_outline),
              ),
              _label('تاريخ الميلاد'),
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
                    decoration: _decoration(
                      'تاريخ الميلاد',
                      Icons.calendar_today_outlined,
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('المهنة'),
                        TextField(
                          controller: _occupationController,
                          textAlign: TextAlign.right,
                          decoration: _decoration('المهنة', Icons.work_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _label('المستوى التعليمي'),
                        DropdownButtonFormField<String>(
                          initialValue: _educationLevel,
                          decoration: _decoration(
                            'اختاري',
                            Icons.school_outlined,
                          ),
                          items: _educationLevels
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _educationLevel = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              _label('المدينة'),
              DropdownButtonFormField<String>(
                initialValue: _city,
                decoration: _decoration(
                  'اختاري المدينة',
                  Icons.location_city_outlined,
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _city = v),
              ),
              _label('الحالة العائلية'),
              DropdownButtonFormField<String>(
                initialValue: _maritalStatus,
                decoration: _decoration('اختاري', Icons.people_outline),
                items: _maritalStatuses
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _maritalStatus = v),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'متابعة',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 14, color: darkGreen),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'جميع بياناتك محمية ولا تظهر للمستخدمين الآخرين',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
