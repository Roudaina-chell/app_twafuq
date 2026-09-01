// screens/auth/login_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import '../../pages/location_check_page.dart';
import '../../services/device_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const Color darkGreen = Color(0xFF0F3D2E);
  static const Color gold = Color(0xFFC9A24B);
  static const Color bg = Color(0xFFFAF7F2);

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  @override
  void initState() {
    super.initState();
    _initGoogleSignIn();
  }

  Future<void> _initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '927146446452-gb1h8lobf21rlqe9thfsoejcethou26e.apps.googleusercontent.com',
      );
      if (mounted) {
        setState(() {
          _googleInitialized = true;
        });
      }
    } catch (e) {
      // فشل التهيئة – الزر يبقى معطل
    }
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LocationCheckPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = friendlyAuthError(e.code);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _findExistingUidForDevice(String deviceId) async {
    final result = await FirebaseFirestore.instance
        .collection('users')
        .where('deviceId', isEqualTo: deviceId)
        .limit(1)
        .get();

    if (result.docs.isEmpty) return null;
    return result.docs.first.data()['uid'] as String?;
  }

  Future<void> _loginWithGoogle() async {
    if (!_googleInitialized) {
      setState(() {
        _errorMessage = 'تسجيل الدخول بـ Google لسا كيتهيأ، عاودي المحاولة';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (!_googleSignIn.supportsAuthenticate()) {
        setState(() {
          _errorMessage =
              'تسجيل الدخول بـ Google غير مدعوم مباشرة فـ هاذ المتصفح حالياً';
        });
        return;
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final idToken = googleUser.authentication.idToken;

      if (idToken == null) {
        setState(() {
          _errorMessage = 'ماقدرناش نجيبو معلومات الحساب من Google';
        });
        return;
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user!;
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

      final deviceId = await DeviceService.getDeviceId();
      final existingUid = await _findExistingUidForDevice(deviceId);

      if (existingUid != null && existingUid != user.uid) {
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();

        if (isNewUser) {
          try {
            await user.delete();
          } catch (_) {}
        }

        if (!mounted) return;
        setState(() {
          _errorMessage =
              'هذا الهاتف مرتبط بحساب موجود من قبل، لا يمكن استخدام حساب Google آخر.';
        });
        return;
      }

      if (isNewUser) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'deviceId': deviceId,
          'method': 'google',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LocationCheckPage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ فـ تسجيل الدخول بـ Google: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendPasswordReset() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('استرجاع كلمة المرور'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          textAlign: TextAlign.right,
          decoration: const InputDecoration(hintText: 'البريد الإلكتروني'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تصيفط ليك رابط إعادة تعيين كلمة المرور على بريدك الإلكتروني',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyAuthError(e.code))));
      }
    }
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: darkGreen.withValues(alpha: 0.7)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: gold, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.language, color: darkGreen, size: 20),
                  SizedBox(width: 6),
                  Text(
                    'العربية',
                    style: TextStyle(
                      color: darkGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down, color: darkGreen),
                ],
              ),
              const SizedBox(height: 6),
              Center(
                child: Column(
                  children: [
                    // ========== الشعار الحقيقي ==========
                    Image.asset(
                      'assets/images/logo_tawafuq.png',
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'PactWed',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: darkGreen,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ميثاق الزواج',
                      style: TextStyle(
                        color: gold,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.right,
                decoration: _fieldDecoration(
                  hint: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                ),
              ),
              const SizedBox(height: 14),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textAlign: TextAlign.right,
                decoration: _fieldDecoration(
                  hint: 'كلمة المرور',
                  icon: Icons.lock_outline,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _sendPasswordReset,
                  child: const Text(
                    'هل نسيت كلمة المرور؟',
                    style: TextStyle(color: darkGreen),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
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
              const SizedBox(height: 12),
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text('أو', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  // ====== الشعار: صورة من الإنترنت مع بديل احتياطي ======
                  icon: Image.network(
                    'https://developers.google.com/identity/images/g-logo.png',
                    width: 20,
                    height: 20,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: Colors.blue,
                    ),
                  ),
                  label: const Text(
                    'تسجيل الدخول باستخدام Google',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('ليس لديك حساب؟ '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'إنشاء حساب جديد',
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

// دالة مساعدة موجودة في register_screen.dart، نضيفها هنا لتجنب الأخطاء
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
