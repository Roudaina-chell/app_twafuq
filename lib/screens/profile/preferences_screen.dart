// screens/profile/preferences_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'about_you_screen.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  RangeValues _ageRange = const RangeValues(22, 35);
  double _maxDistance = 50;
  String? _preferredWilaya;
  bool _isSubmitting = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<String> _wilayas = const [
    'بدون تفضيل',
    'الجزائر العاصمة',
    'البليدة',
    'بومرداس',
    'تيبازة',
    'وهران',
    'قسنطينة',
    'عنابة',
  ];

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
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isSubmitting = true;
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
        'preferences': {
          'ageMin': _ageRange.start.round(),
          'ageMax': _ageRange.end.round(),
          'maxDistanceKm': _maxDistance.round(),
          'preferredWilaya':
              (_preferredWilaya == null || _preferredWilaya == 'بدون تفضيل')
              ? null
              : _preferredWilaya,
        },
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AboutYouScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'وقع خطأ، عاود المحاولة';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: FadeTransition(
            opacity: _fadeAnimation,
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
                          value: 1.0,
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
                    width: 80,
                    height: 80,
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
                      border: Border.all(color: gold.withValues(alpha: 0.3)),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: darkGreen,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'حدد تفضيلاتك',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'هاذ المعلومات تعاون فـ اقتراح الملفات اللي تناسبك',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 24),

                // بطاقة نطاق العمر
                _PreferenceCard(
                  icon: Icons.cake_outlined,
                  title: 'نطاق العمر',
                  trailing:
                      '${_ageRange.start.round()} - ${_ageRange.end.round()} سنة',
                  child: RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 60,
                    divisions: 42,
                    activeColor: darkGreen,
                    inactiveColor: darkGreen.withValues(alpha: 0.15),
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    onChanged: (values) {
                      setState(() {
                        _ageRange = values;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة المسافة القصوى
                _PreferenceCard(
                  icon: Icons.location_on_outlined,
                  title: 'المسافة القصوى',
                  trailing: '${_maxDistance.round()} كم',
                  child: Slider(
                    value: _maxDistance,
                    min: 5,
                    max: 200,
                    divisions: 39,
                    activeColor: darkGreen,
                    inactiveColor: darkGreen.withValues(alpha: 0.15),
                    label: '${_maxDistance.round()} كم',
                    onChanged: (value) {
                      setState(() {
                        _maxDistance = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // بطاقة الولاية المفضلة
                _PreferenceCard(
                  icon: Icons.map_outlined,
                  title: 'الولاية المفضلة',
                  child: DropdownButtonFormField<String>(
                    initialValue: _preferredWilaya ?? 'بدون تفضيل',
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down, color: darkGreen),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: darkGreen.withValues(alpha: 0.04),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    items: _wilayas
                        .map(
                          (w) => DropdownMenuItem<String>(
                            value: w,
                            child: Text(w, style: const TextStyle(fontSize: 14)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _preferredWilaya = value;
                      });
                    },
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
                const SizedBox(height: 24),

                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [darkGreen, Color(0xFF1A6B4A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: darkGreen.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSubmitting ? null : _submit,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'إنهاء',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
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
                        'تقدر تبدل هاذ التفضيلات فـ أي وقت من إعدادات الملف الشخصي',
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
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  static const Color darkGreen = Color(0xFF0F3D2E);

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;

  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: darkGreen, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: darkGreen,
                    fontSize: 14,
                  ),
                ),
              ),
              if (trailing != null)
                Text(
                  trailing!,
                  style: const TextStyle(
                    color: darkGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}