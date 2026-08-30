// screens/auth/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'login_screen.dart';
import '../../services/device_service.dart';

String friendlyAuthError(String code) {
  switch (code) {
    case 'email-already-in-use':
      return 'هاذ البريد الإلكتروني مستعمل من قبل، جربي تسجيل الدخول';

    case 'invalid-email':
      return 'صيغة البريد الإلكتروني غير صحيحة';

    case 'weak-password':
      return 'كلمة المرور ضعيفة، خاصها 6 حروف/أرقام على الأقل';

    case 'user-not-found':
      return 'ماكاين حتى حساب بهاذ البريد الإلكتروني';

    case 'wrong-password':
    case 'invalid-credential':
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة';

    case 'network-request-failed':
      return 'تأكدي من الاتصال بالإنترنت وعاودي المحاولة';

    default:
      return 'وقع خطأ، عاودي المحاولة ($code)';
  }
}

Future<bool> isDeviceAlreadyRegistered(String deviceId) async {
  final result = await FirebaseFirestore.instance
      .collection('users')
      .where('deviceId', isEqualTo: deviceId)
      .limit(1)
      .get();

  return result.docs.isNotEmpty;
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  String? _errorMessage;

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);

  Future<void> _register() async {
    // 1️⃣ Vérification des champs
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'خاصك تعمري جميع الحقول';
      });
      return;
    }

    // 2️⃣ Vérification password
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'كلمتا المرور غير متطابقتين';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 3️⃣ الحصول على Device ID
      final deviceId = await DeviceService.getDeviceId();

      if (deviceId.isEmpty) {
        throw Exception('Device ID غير متوفر');
      }

      // 4️⃣ التحقق هل الجهاز مسجل من قبل
      final alreadyRegistered = await isDeviceAlreadyRegistered(deviceId);

      if (alreadyRegistered) {
        if (!mounted) return;

        setState(() {
          _errorMessage =
              'هذا الهاتف مرتبط بحساب موجود من قبل، لا يمكن إنشاء حساب آخر.';
        });

        return;
      }

      // 5️⃣ إنشاء حساب Firebase بالإيميل
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );

      // 6️⃣ إضافة الاسم لحساب Firebase
      await credential.user?.updateDisplayName(_nameController.text.trim());

      // 7️⃣ حفظ بيانات المستخدم + Device ID في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'uid': credential.user!.uid,
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'deviceId': deviceId,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 8️⃣ الانتقال إلى Login
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = friendlyAuthError(e.code);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'وقع خطأ غير متوقع، عاودي المحاولة';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,

                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: darkGreen),

                  onPressed: () => Navigator.pop(context),
                ),
              ),

              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: gold, width: 2),
                      ),

                      child: const Icon(
                        Icons.favorite,
                        color: darkGreen,
                        size: 40,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'TAWAFUQ',

                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 4),

                    const Text(
                      'توافقك الحقيقي',

                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'إنشاء حساب جديد',

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              const Text(
                'املأ بياناتك للانضمام إلينا',

                textAlign: TextAlign.center,

                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // NAME
              TextField(
                controller: _nameController,

                textAlign: TextAlign.right,

                decoration: InputDecoration(
                  hintText: 'الاسم الكامل',

                  prefixIcon: const Icon(Icons.person_outline),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // EMAIL
              TextField(
                controller: _emailController,

                keyboardType: TextInputType.emailAddress,

                textAlign: TextAlign.right,

                decoration: InputDecoration(
                  hintText: 'البريد الإلكتروني',

                  prefixIcon: const Icon(Icons.email_outlined),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // PASSWORD
              TextField(
                controller: _passwordController,

                obscureText: _obscurePassword,

                textAlign: TextAlign.right,

                decoration: InputDecoration(
                  hintText: 'كلمة المرور',

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // CONFIRM PASSWORD
              TextField(
                controller: _confirmPasswordController,

                obscureText: _obscureConfirmPassword,

                textAlign: TextAlign.right,

                decoration: InputDecoration(
                  hintText: 'تأكيد كلمة المرور',

                  prefixIcon: const Icon(Icons.lock_outline),

                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),

                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),

                Text(
                  _errorMessage!,

                  textAlign: TextAlign.center,

                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              SizedBox(
                height: 52,

                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'إنشاء الحساب',

                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  const Text('لديك حساب بالفعل؟ '),

                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },

                    child: const Text(
                      'تسجيل الدخول',

                      style: TextStyle(
                        color: darkGreen,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
