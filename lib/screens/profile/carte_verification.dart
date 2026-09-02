// screens/profile/carte_verification.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'formulaire_info.dart';

class CarteVerification extends StatefulWidget {
  const CarteVerification({super.key});

  @override
  State<CarteVerification> createState() => _CarteVerificationState();
}

class _CarteVerificationState extends State<CarteVerification>
    with SingleTickerProviderStateMixin {
  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  File? _pickedImage;
  bool _isUploading = false;
  String? _errorMessage;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

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

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() {
          _pickedImage = File(file.path);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'ماقدرناش نوصلو للكاميرا/المعرض';
      });
    }
  }

  Future<bool> _isValidAlgerianId(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );

      final String rawText = recognizedText.text;
      final String upperText = rawText.toUpperCase();

      final bool hasArabicMarker =
          rawText.contains('الجمهورية') ||
          rawText.contains('بطاقة التعريف') ||
          rawText.contains('التعريف الوطني');

      final bool hasFrenchMarker =
          upperText.contains('REPUBLIQUE ALGERIENNE') ||
          upperText.contains('ALGERIENNE DEMOCRATIQUE');

      final bool hasMrzMarker = upperText.contains('IDDZA');

      return hasArabicMarker || hasFrenchMarker || hasMrzMarker;
    } catch (e) {
      return false;
    }
  }

  Future<void> _submit() async {
    if (_pickedImage == null) {
      setState(() {
        _errorMessage = 'خاصك تصوري ولا تختاري صورة البطاقة أولاً';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      final bool isValid = await _isValidAlgerianId(_pickedImage!);

      if (!isValid) {
        setState(() {
          _errorMessage =
              'الصورة ماشي واضحة ولا ماشي بطاقة تعريف وطنية. صوري الوجه ولا الظهر بوضوح وعاودي المحاولة';
        });
        return;
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _errorMessage = 'خطأ: ماكاين حتى مستخدم مسجل الدخول';
        });
        return;
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'verificationStatus': 'submitted',
      }, SetOptions(merge: true));

      try {
        if (await _pickedImage!.exists()) {
          await _pickedImage!.delete();
        }
      } catch (_) {}

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FormulaireInfo()),
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
          _isUploading = false;
        });
      }
    }
  }

  // ============================================================
  // ✅ تخطي هذه الخطوة (Skip)
  // ============================================================
  Future<void> _skip() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'verificationStatus': 'skipped',
        }, SetOptions(merge: true));
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FormulaireInfo()),
        (route) => false,
      );
    }
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
                  // ============================================================
                  // HEADER مع شريط التقدم
                  // ============================================================
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: darkGreen,
                          size: 20,
                        ),
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
                            value: 0.2,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              gold,
                            ),
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
                          '1/5',
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

                  // ============================================================
                  // أيقونة كبيرة
                  // ============================================================
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
                        border: Border.all(
                          color: gold.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.credit_card_outlined,
                        color: darkGreen,
                        size: 34,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ============================================================
                  // العنوان والوصف
                  // ============================================================
                  const Text(
                    'التقاط صورة البطاقة الوطنية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkGreen,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'ضع بطاقتك الوطنية داخل الإطار وتأكد من ظهور جميع المعلومات بوضوح',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ============================================================
                  // منطقة عرض الصورة
                  // ============================================================
                  Container(
                    height: 240,
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: _pickedImage == null
                          ? _buildPlaceholder()
                          : Image.file(
                              _pickedImage!,
                              width: double.infinity,
                              height: 240,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ============================================================
                  // زر الكاميرا (دائري كبير)
                  // ============================================================
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // تأثير تموج
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 2000),
                          tween: Tween<double>(begin: 0, end: 1),
                          curve: Curves.easeInOut,
                          builder: (context, double value, child) {
                            return Container(
                              width: 100 + (value * 20),
                              height: 100 + (value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: gold.withValues(
                                  alpha: 0.08 * (1 - value * 0.6),
                                ),
                              ),
                            );
                          },
                        ),
                        GestureDetector(
                          onTap: () => _pickImage(ImageSource.camera),
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [darkGreen, Color(0xFF1A6B4A)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: darkGreen.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'اضغط للتصوير',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ============================================================
                  // خط فاصل مع "أو"
                  // ============================================================
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'أو',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ============================================================
                  // زر اختيار من المعرض
                  // ============================================================
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: Colors.white,
                      ),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: darkGreen,
                        size: 22,
                      ),
                      label: const Text(
                        'اختيار صورة من المعرض',
                        style: TextStyle(
                          color: darkGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // ============================================================
                  // عرض الخطأ
                  // ============================================================
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

                  // ============================================================
                  // زر متابعة
                  // ============================================================
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkGreen,
                        elevation: 4,
                        shadowColor: darkGreen.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
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

                  const SizedBox(height: 12),

                  // ============================================================
                  // زر التخطي (Skip)
                  // ============================================================
                  Center(
                    child: TextButton(
                      onPressed: _isUploading ? null : _skip,
                      child: Text(
                        'تخطي هذه الخطوة',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ============================================================
                  // ملاحظة الخصوصية
                  // ============================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 16,
                        color: darkGreen,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'صورتك تُستخدم فقط للتحقق ولا يتم مشاركتها مع أي طرف ثالث',
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

  // ============================================================
  // مكان الصورة الافتراضي (عندما لا توجد صورة)
  // ============================================================
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            darkGreen.withValues(alpha: 0.04),
            gold.withValues(alpha: 0.06),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // إطار متقطع حول الأيقونة
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: gold.withValues(alpha: 0.3),
                width: 1.5,
                style: BorderStyle.solid,
              ),
            ),
            child: Icon(
              Icons.credit_card_outlined,
              color: gold.withValues(alpha: 0.5),
              size: 48,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'لم يتم اختيار صورة بعد',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Text(
            'اضغط على زر الكاميرا للتصوير\nأو اختر من المعرض',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
