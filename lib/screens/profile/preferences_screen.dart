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
  late Animation<Offset> _slideAnimation;

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
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // HEADER
                  // ==================================================
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: darkGreen.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: darkGreen,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'TAWAFUQ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkGreen,
                          letterSpacing: 1,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: 1.0,
                            minHeight: 7,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(gold),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // ICON
                  // ==================================================
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
                            darkGreen.withValues(alpha: 0.08),
                            gold.withValues(alpha: 0.14),
                          ],
                        ),
                        border: Border.all(color: gold.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: darkGreen.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: darkGreen,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'حدد تفضيلاتك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هاذ المعلومات تعاون فـ اقتراح الملفات اللي تناسبك',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black45,
                      fontSize: 13.5,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),

                  // بطاقة نطاق العمر
                  _PreferenceCard(
                    icon: Icons.cake_outlined,
                    title: 'نطاق العمر',
                    trailing:
                        '${_ageRange.start.round()} - ${_ageRange.end.round()} سنة',
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 9,
                          elevation: 3,
                        ),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTrackColor: darkGreen,
                        inactiveTrackColor: darkGreen.withValues(alpha: 0.12),
                        thumbColor: darkGreen,
                        valueIndicatorColor: darkGreen,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 60,
                        divisions: 42,
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
                    footerLeft: '18',
                    footerRight: '60',
                  ),
                  const SizedBox(height: 14),

                  // بطاقة المسافة القصوى
                  _PreferenceCard(
                    icon: Icons.location_on_outlined,
                    title: 'المسافة القصوى',
                    trailing: '${_maxDistance.round()} كم',
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 5,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 9, elevation: 3),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 18),
                        activeTrackColor: darkGreen,
                        inactiveTrackColor: darkGreen.withValues(alpha: 0.12),
                        thumbColor: darkGreen,
                        valueIndicatorColor: darkGreen,
                        valueIndicatorTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: Slider(
                        value: _maxDistance,
                        min: 5,
                        max: 200,
                        divisions: 39,
                        label: '${_maxDistance.round()} كم',
                        onChanged: (value) {
                          setState(() {
                            _maxDistance = value;
                          });
                        },
                      ),
                    ),
                    footerLeft: '5 كم',
                    footerRight: '200 كم',
                  ),
                  const SizedBox(height: 14),

                  // بطاقة الولاية المفضلة
                  _PreferenceCard(
                    icon: Icons.map_outlined,
                    title: 'الولاية المفضلة',
                    child: DropdownButtonFormField<String>(
                      initialValue: _preferredWilaya ?? 'بدون تفضيل',
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: darkGreen),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: darkGreen.withValues(alpha: 0.045),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: gold.withValues(alpha: 0.5)),
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 14,
                        color: darkGreen,
                        fontWeight: FontWeight.w600,
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

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _errorMessage != null
                        ? Container(
                            key: const ValueKey('err'),
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
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
                          )
                        : const SizedBox(key: ValueKey('noerr'), height: 0),
                  ),

                  const SizedBox(height: 26),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [darkGreen, Color(0xFF1A6B4A)],
                      ),
                      borderRadius: BorderRadius.circular(18),
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
                        borderRadius: BorderRadius.circular(18),
                        child: Center(
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.check_circle_outline_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'إنهاء',
                                      style: TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 13, color: darkGreen),
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
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  final IconData icon;
  final String title;
  final String? trailing;
  final Widget child;
  final String? footerLeft;
  final String? footerRight;

  const _PreferenceCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
    this.footerLeft,
    this.footerRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: darkGreen.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: darkGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: darkGreen, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: darkGreen,
                    fontSize: 14.5,
                  ),
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
          child,
          if (footerLeft != null && footerRight != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    footerLeft!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  Text(
                    footerRight!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}