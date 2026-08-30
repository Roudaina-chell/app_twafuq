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
      // فشل تهيئة Google Sign-In - زر Google غادي يبقى معطل
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

  // ============================================================
  // ✅ دالة جديدة: تتحقق واش الجهاز مربوط بحساب آخر (users/deviceId)
  // كتستعمل نفس المنطق تاع register_screen.dart
  // ترجع uid تاع الحساب الآخر، ولا null إلا الجهاز فاضي
  // ============================================================
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

      // ============================================================
      // ✅ التحقق من الجهاز - هنا كان الخلل قبل
      // ============================================================
      final deviceId = await DeviceService.getDeviceId();
      final existingUid = await _findExistingUidForDevice(deviceId);

      if (existingUid != null && existingUid != user.uid) {
        // الجهاز مربوط بحساب آخر (غير هذا) → منع
        await FirebaseAuth.instance.signOut();
        await _googleSignIn.signOut();

        // إلا Google خلق حساب جديد دابا، خاصنا نمسحوه باش ما يبقاش يتيم
        if (isNewUser) {
          try {
            await user.delete();
          } catch (_) {
            // إلا فشل المسح (نادر)، السيشن ديجا خرجنا منها فوق
          }
        }

        if (!mounted) return;
        setState(() {
          _errorMessage =
              'هذا الهاتف مرتبط بحساب موجود من قبل، لا يمكن استخدام حساب Google آخر.';
        });
        return;
      }

      // إلا كان حساب Google جديد (أول مرة) وما كاينش تضارب → سجلو فـ users
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
              const SizedBox(height: 10),
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
              const SizedBox(height: 30),
              const Text(
                'مرحباً بك',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'سجل دخولك للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
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
                      setState(() => _obscurePassword = !_obscurePassword);
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
              const SizedBox(height: 10),
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
                const SizedBox(height: 6),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'تسجيل الدخول',
                          style: TextStyle(fontSize: 16, color: Colors.white),
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
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.g_mobiledata,
                    color: Colors.red,
                    size: 28,
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
